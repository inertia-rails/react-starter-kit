import { router, usePage } from "@inertiajs/react"
import { useEffect, useState } from "react"
import { toast } from "sonner"

import type { Flash } from "@/types"

const emptyFlash = {}

export const useFlash = () => {
  const { flash } = usePage().props
  const [currentFlash, setCurrentFlash] = useState<Flash>(emptyFlash)

  useEffect(() => {
    setCurrentFlash(flash)
  }, [flash])

  router.on("start", () => {
    setCurrentFlash(emptyFlash)
  })

  useEffect(() => {
    if (currentFlash.alert) {
      toast.error(currentFlash.alert)
    }
    if (currentFlash.notice) {
      toast(currentFlash.notice)
    }
  }, [currentFlash])
}
