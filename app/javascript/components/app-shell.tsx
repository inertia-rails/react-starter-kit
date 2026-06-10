import { useState } from "react"

import { SidebarProvider } from "@/components/ui/sidebar"
import * as storage from "@/lib/storage"

interface AppShellProps {
  children: React.ReactNode
  variant?: "header" | "sidebar"
}

export function AppShell({ children, variant = "header" }: AppShellProps) {
  const [isOpen, setIsOpen] = useState(
    () => storage.getItem("sidebar") !== "false",
  )

  const handleSidebarChange = (open: boolean) => {
    setIsOpen(open)
    storage.setItem("sidebar", String(open))
  }

  if (variant === "header") {
    return <div className="flex min-h-screen w-full flex-col">{children}</div>
  }

  return (
    <SidebarProvider
      defaultOpen={isOpen}
      open={isOpen}
      onOpenChange={handleSidebarChange}
    >
      {children}
    </SidebarProvider>
  )
}
