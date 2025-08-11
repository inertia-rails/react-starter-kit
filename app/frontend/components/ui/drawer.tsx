"use client"

import type * as React from "react"

import {
  Sheet,
  SheetClose,
  SheetContent,
  SheetDescription,
  SheetFooter,
  SheetHeader,
  SheetTitle,
  SheetTrigger,
} from "@/components/ui/sheet"

// Drawer components using Sheet as base
function Drawer({ ...props }: React.ComponentProps<typeof Sheet>) {
  return <Sheet {...props} />
}

function DrawerTrigger({ ...props }: React.ComponentProps<typeof SheetTrigger>) {
  return <SheetTrigger {...props} />
}

function DrawerClose({ ...props }: React.ComponentProps<typeof SheetClose>) {
  return <SheetClose {...props} />
}

function DrawerContent({
  side = "bottom",
  ...props
}: React.ComponentProps<typeof SheetContent>) {
  return <SheetContent side={side} {...props} />
}

function DrawerHeader({ ...props }: React.ComponentProps<typeof SheetHeader>) {
  return <SheetHeader {...props} />
}

function DrawerFooter({ ...props }: React.ComponentProps<typeof SheetFooter>) {
  return <SheetFooter {...props} />
}

function DrawerTitle({ ...props }: React.ComponentProps<typeof SheetTitle>) {
  return <SheetTitle {...props} />
}

function DrawerDescription({
  ...props
}: React.ComponentProps<typeof SheetDescription>) {
  return <SheetDescription {...props} />
}

export {
  Drawer,
  DrawerClose,
  DrawerContent,
  DrawerDescription,
  DrawerFooter,
  DrawerHeader,
  DrawerTitle,
  DrawerTrigger,
}