import { Head, useForm } from "@inertiajs/react"
import { LoaderCircle } from "lucide-react"
import type { FormEventHandler } from "react"

import InputError from "@/components/input-error"
import TextLink from "@/components/text-link"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import AuthLayout from "@/layouts/auth-layout"
import { newIdentityPasswordResetPath, signInPath, signUpPath } from "@/routes"

interface LoginForm {
  email: string
  password: string
}

export default function Login() {
  const { data, setData, post, processing, errors, reset } = useForm<
    Required<LoginForm>
  >({
    email: "",
    password: "",
  })

  const submit: FormEventHandler = (e) => {
    e.preventDefault()
    post(signInPath(), {
      onFinish: () => reset("password"),
    })
  }

  return (
    <AuthLayout
      title="Log in to your account"
      description="Enter your email and password below to log in"
    >
      <Head title="Log in" />

      <form className="flex flex-col gap-6" onSubmit={submit}>
        <div className="grid gap-6">
          <div className="grid gap-2">
            <Label htmlFor="email">Email address</Label>
            <Input
              id="email"
              type="email"
              required
              autoFocus
              tabIndex={1}
              autoComplete="email"
              value={data.email}
              onChange={(e) => setData("email", e.target.value)}
              placeholder="email@example.com"
            />
            <InputError message={errors.email} />
          </div>

          <div className="grid gap-2">
            <div className="flex items-center">
              <Label htmlFor="password">Password</Label>
              <TextLink
                href={newIdentityPasswordResetPath()}
                className="ml-auto text-sm"
                tabIndex={5}
              >
                Forgot password?
              </TextLink>
            </div>
            <Input
              id="password"
              type="password"
              required
              tabIndex={2}
              autoComplete="current-password"
              value={data.password}
              onChange={(e) => setData("password", e.target.value)}
              placeholder="Password"
            />
            <InputError message={errors.password} />
          </div>

          <Button
            type="submit"
            className="mt-4 w-full"
            tabIndex={4}
            disabled={processing}
          >
            {processing && <LoaderCircle className="h-4 w-4 animate-spin" />}
            Log in
          </Button>
        </div>

        <div className="text-muted-foreground text-center text-sm">
          Don&apos;t have an account?{" "}
          <TextLink href={signUpPath()} tabIndex={5}>
            Sign up
          </TextLink>
        </div>
      </form>
    </AuthLayout>
  )
}
