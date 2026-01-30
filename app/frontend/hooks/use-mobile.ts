import { useSyncExternalStore } from "react"

const MOBILE_BREAKPOINT = 768

const query = `(max-width: ${MOBILE_BREAKPOINT - 1}px)`

function getMql(): MediaQueryList | null {
  if (typeof window === "undefined") return null
  return window.matchMedia(query)
}

function mediaQueryListener(callback: (event: MediaQueryListEvent) => void) {
  const mql = getMql()
  if (!mql) return () => undefined

  mql.addEventListener("change", callback)

  return () => {
    mql.removeEventListener("change", callback)
  }
}

function isSmallerThanBreakpoint() {
  return getMql()?.matches ?? false
}

export function useIsMobile() {
  return useSyncExternalStore(
    mediaQueryListener,
    isSmallerThanBreakpoint,
    () => false,
  )
}
