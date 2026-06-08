import type { ReactNode } from "react"

import AuthLayoutTemplate from "@/layouts/auth/auth-simple-layout"

export default function AuthLayout({
  children,
  title,
  description,
  ...props
}: {
  children: ReactNode
  title: string
  description: string
}) {
  return (
    <AuthLayoutTemplate title={title} description={description} {...props}>
      {children}
    </AuthLayoutTemplate>
  )
}
