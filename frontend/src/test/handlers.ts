import { http, HttpResponse } from 'msw'
import { runFixtures, runsPage, variantFixtures } from './fixtures'

export const capturedRunRequests: URL[] = []

/** Default success handlers: variants + runs + empty metrics. */
export const successHandlers = [
  http.get('*/api/variants', () => HttpResponse.json(variantFixtures)),
  http.get('*/api/runs', ({ request }) => {
    capturedRunRequests.push(new URL(request.url))
    return HttpResponse.json(runsPage(runFixtures))
  }),
  http.get('*/api/metrics/acceptance', () => HttpResponse.json([])),
  http.get('*/api/metrics/cost-latency', () => HttpResponse.json([])),
]

export function clearCapturedRunRequests() {
  capturedRunRequests.length = 0
}
