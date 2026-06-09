import type { LucideProps } from "lucide-react"
import type { ComponentType } from "react"

import { cn } from "@/lib/utils"

type IconProps = {
  iconNode: ComponentType<LucideProps>
} & Omit<LucideProps, "ref">

export function Icon({
  iconNode: IconComponent,
  className,
  ...props
}: IconProps) {
  return <IconComponent className={cn("h-4 w-4", className)} {...props} />
}
