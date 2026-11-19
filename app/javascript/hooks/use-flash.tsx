import { router } from "@inertiajs/react"
import { useEffect } from "react"
import { toast } from "sonner"

export function useFlash() {
  useEffect(() => {
    return router.on("flash", (event) => {
      const { flash } = event.detail
      if (flash.alert) toast.error(flash.alert)
      if (flash.notice) toast(flash.notice)
    })
  }, [])
}
