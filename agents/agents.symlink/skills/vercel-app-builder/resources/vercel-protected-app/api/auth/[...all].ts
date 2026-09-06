import { auth } from "../../auth.js"

export const config = {
  runtime: "nodejs",
}

export const GET = (request: Request) => auth.handler(request)
export const POST = (request: Request) => auth.handler(request)
