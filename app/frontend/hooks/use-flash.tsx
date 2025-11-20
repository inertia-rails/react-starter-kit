import { router } from "@inertiajs/react"
import { toast } from "sonner"

import type { Flash } from "@/types"

export const useFlash = () => {
  router.on("beforeUpdate", (event) => {
    const flash = event.detail.page.props.flash as Flash
    if (flash.alert) {
      toast.error(flash.alert)
    }
    if (flash.notice) {
      toast(flash.notice)
    }
    event.detail.page.props.flash = {}
  })
}
