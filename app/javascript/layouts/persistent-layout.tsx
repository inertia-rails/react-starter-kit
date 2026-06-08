import type { ReactNode } from "react"

import { Toaster } from "@/components/ui/sonner"
import { useFlash } from "@/hooks/use-flash"

interface PersistentLayoutProps {
  children: ReactNode
}

export default function PersistentLayout({ children }: PersistentLayoutProps) {
  useFlash()
  return (
    <>
      {children}
      <Toaster richColors />
    </>
  )
}
