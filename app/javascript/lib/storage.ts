import { isBrowser } from "./browser"

export function getItem(key: string): string | null {
  return isBrowser ? localStorage.getItem(key) : null
}

export function setItem(key: string, value: string): void {
  if (isBrowser) localStorage.setItem(key, value)
}

export function removeItem(key: string): void {
  if (isBrowser) localStorage.removeItem(key)
}
