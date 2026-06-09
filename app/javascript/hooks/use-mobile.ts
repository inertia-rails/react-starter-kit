import { useSyncExternalStore } from "react"

import { isBrowser } from "@/lib/browser"

const MOBILE_BREAKPOINT = 768

const mql = isBrowser
  ? window.matchMedia(`(max-width: ${MOBILE_BREAKPOINT - 1}px)`)
  : null

function mediaQueryListener(callback: (event: MediaQueryListEvent) => void) {
  mql?.addEventListener("change", callback)

  return () => {
    mql?.removeEventListener("change", callback)
  }
}

function isSmallerThanBreakpoint() {
  return mql?.matches ?? false
}

export function useIsMobile() {
  return useSyncExternalStore(
    mediaQueryListener,
    isSmallerThanBreakpoint,
    () => false,
  )
}
