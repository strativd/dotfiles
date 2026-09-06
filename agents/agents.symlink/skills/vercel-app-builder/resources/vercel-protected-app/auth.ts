import { betterAuth } from "better-auth"

function parseEmailList(value: string | undefined): string[] {
  if (!value) return []
  return value.split(",").map(entry => entry.trim().toLowerCase()).filter(Boolean)
}

export function getAllowedGoogleHd(): string | null {
  const value = process.env.APP_ALLOWED_GOOGLE_HD?.trim()
  if (!value || value === "-") return null
  return value.toLowerCase()
}

export function isAllowedEmail(email: string | undefined): boolean {
  if (!email) return false
  const normalized = email.trim().toLowerCase()
  const allowedEmails = parseEmailList(process.env.APP_ALLOWED_EMAILS)
  if (allowedEmails.includes(normalized)) return true
  const hostedDomain = getAllowedGoogleHd()
  return Boolean(hostedDomain && normalized.endsWith(`@${hostedDomain}`))
}

export function isGoogleAuthConfigured(): boolean {
  const clientId = process.env.GOOGLE_CLIENT_ID?.trim()
  const clientSecret = process.env.GOOGLE_CLIENT_SECRET?.trim()
  const secret = process.env.BETTER_AUTH_SECRET?.trim()
  const baseURL = process.env.BETTER_AUTH_URL?.trim()
  if (!clientId || !clientSecret || !secret || !baseURL) return false
  if (clientId === "pending" || clientSecret === "pending") return false
  return parseEmailList(process.env.APP_ALLOWED_EMAILS).length > 0 || Boolean(getAllowedGoogleHd())
}

const trustedOrigins = [
  process.env.BETTER_AUTH_URL,
  "http://localhost:5173",
  "http://localhost:3000",
].filter((origin): origin is string => Boolean(origin))

export const auth = betterAuth({
  secret: process.env.BETTER_AUTH_SECRET,
  baseURL: process.env.BETTER_AUTH_URL,
  trustedOrigins,
  session: {
    cookieCache: {
      enabled: true,
      maxAge: 60 * 60 * 24 * 7,
      strategy: "jwe",
      refreshCache: true,
    },
  },
  account: {
    storeStateStrategy: "cookie",
    storeAccountCookie: true,
  },
  socialProviders: {
    google: {
      clientId: process.env.GOOGLE_CLIENT_ID ?? "",
      clientSecret: process.env.GOOGLE_CLIENT_SECRET ?? "",
      requireEmailVerification: true,
    },
  },
  user: {
    validateUserInfo: ({ user }) => {
      if (!isAllowedEmail(user.email)) {
        return {
          error: "email_not_allowed",
          errorDescription: "This Google account is not on the allowlist.",
        }
      }
    },
  },
})
