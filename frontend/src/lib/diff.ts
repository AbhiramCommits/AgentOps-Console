export type DiffLineType = 'context' | 'added' | 'removed'

export interface DiffLine {
  type: DiffLineType
  text: string
  oldLine: number | null
  newLine: number | null
}

export interface DiffHunk {
  header: string
  lines: DiffLine[]
}

export interface ParsedDiff {
  hunks: DiffHunk[]
}

interface HunkRange {
  oldStart: number
  oldCount: number
  newStart: number
  newCount: number
}

function parseHunkHeader(line: string): HunkRange | null {
  const match = /^@@ -(\d+)(?:,(\d+))? \+(\d+)(?:,(\d+))? @@/.exec(line)
  if (!match) return null
  return {
    oldStart: Number(match[1] ?? '0'),
    oldCount: match[2] == null ? 1 : Number(match[2]),
    newStart: Number(match[3] ?? '0'),
    newCount: match[4] == null ? 1 : Number(match[4]),
  }
}

/**
 * Parses a git unified diff into hunks with per-line type and line numbers.
 * Lines before the first hunk header (diff --git / index / --- / +++) are
 * skipped; if no hunk header is found the whole input is treated as context.
 */
export function parseUnifiedDiff(diff: string): ParsedDiff {
  const hunks: DiffHunk[] = []
  let current: DiffHunk | null = null
  let oldLine = 0
  let newLine = 0

  for (const raw of diff.split('\n')) {
    if (raw.length === 0) continue

    const hunkHeader = parseHunkHeader(raw)
    if (hunkHeader) {
      current = { header: raw, lines: [] }
      hunks.push(current)
      oldLine = hunkHeader.oldStart
      newLine = hunkHeader.newStart
      continue
    }
    if (current == null) {
      if (raw.startsWith('diff --git') || raw.startsWith('index ') || raw.startsWith('--- ') || raw.startsWith('+++ ') || raw.startsWith('new file') || raw.startsWith('deleted file')) {
        continue
      }
      // Malformed diff without a hunk header: render everything as context.
      current = { header: '', lines: [] }
      hunks.push(current)
    }
    if (raw.startsWith('\\')) {
      // "\ No newline at end of file" — annotate the previous line.
      const previous = current.lines[current.lines.length - 1]
      if (previous) {
        previous.text += ' ⏎'
      }
      continue
    }

    const first = raw[0]
    if (first === '+') {
      current.lines.push({ type: 'added', text: raw.slice(1), oldLine: null, newLine })
      newLine += 1
    } else if (first === '-') {
      current.lines.push({ type: 'removed', text: raw.slice(1), oldLine, newLine: null })
      oldLine += 1
    } else if (first === ' ') {
      current.lines.push({ type: 'context', text: raw.slice(1), oldLine, newLine })
      oldLine += 1
      newLine += 1
    } else {
      current.lines.push({ type: 'context', text: raw, oldLine: null, newLine: null })
    }
  }

  return { hunks }
}

export interface DiffRow {
  hunkHeader: string | null
  left: DiffLine | null
  right: DiffLine | null
}

/** Turns parsed hunks into side-by-side rows for the two-column diff view. */
export function toSideBySideRows(diff: ParsedDiff): DiffRow[] {
  const rows: DiffRow[] = []
  for (const hunk of diff.hunks) {
    if (hunk.header) {
      rows.push({ hunkHeader: hunk.header, left: null, right: null })
    }
    for (const line of hunk.lines) {
      if (line.type === 'removed') {
        rows.push({ hunkHeader: null, left: line, right: null })
      } else if (line.type === 'added') {
        rows.push({ hunkHeader: null, left: null, right: line })
      } else {
        rows.push({ hunkHeader: null, left: line, right: line })
      }
    }
  }
  return rows
}
