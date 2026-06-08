import type { HTMLAttributes } from "react"

import { cn } from "@/lib/utils"

export default function InputError({
  messages,
  className = "",
  ...props
}: HTMLAttributes<HTMLParagraphElement> & { messages?: string[] }) {
  return messages ? (
    <p
      {...props}
      className={cn("text-sm text-red-600 dark:text-red-400", className)}
    >
      {messages.join(", ")}
    </p>
  ) : null
}
