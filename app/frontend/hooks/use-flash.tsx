import { router, usePage } from "@inertiajs/react"
import { useEffect, useRef } from "react"
import { toast } from "sonner"

import type { FlashData } from "@/types"

function showFlash(flash: FlashData) {
  if (flash.alert) {
    toast.error(flash.alert)
  }
  if (flash.notice) {
    toast(flash.notice)
  }
}

export function useFlash() {
  const { flash } = usePage()
  const toastShowed = useRef(false)

  useEffect(() => {
    if (!toastShowed.current) {
      toastShowed.current = true
      showFlash(flash)
    }
  }, [flash])

  useEffect(() => {
    return router.on("flash", (event) => {
      const flash = event.detail.flash
      showFlash(flash)
    })
  }, [])
}
