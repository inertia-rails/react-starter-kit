import { usePage } from "@inertiajs/react"
import { useEffect } from "react"
import { toast } from "sonner"

import type { FlashData } from "@/types"

function showFlash(flash: FlashData) {
  if (flash.alert) toast.error(flash.alert)
  if (flash.notice) toast(flash.notice)
}

export function useFlash() {
  const { flash } = usePage()

  useEffect(() => {
    // setTimeout + cleanup prevents double-firing in React StrictMode
    const timeout = setTimeout(() => showFlash(flash), 0)
    return () => clearTimeout(timeout)
  }, [flash])
}
