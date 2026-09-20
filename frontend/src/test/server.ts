import { setupServer } from 'msw/node'

export const server = setupServer()

export const API_URL_PATTERN = '*/api/*'
