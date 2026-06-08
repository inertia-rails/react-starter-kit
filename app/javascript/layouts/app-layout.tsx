import type { ReactNode } from "react"

import AppLayoutTemplate from "@/layouts/app/app-sidebar-layout"
import type { BreadcrumbItem } from "@/types"

interface AppLayoutProps {
  children: ReactNode
  breadcrumbs?: BreadcrumbItem[]
}

export default function AppLayout({
  children,
  breadcrumbs,
  ...props
}: AppLayoutProps) {
  return (
    <AppLayoutTemplate breadcrumbs={breadcrumbs} {...props}>
      {children}
    </AppLayoutTemplate>
  )
}
