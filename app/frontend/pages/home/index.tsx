import { Head, Link, usePage } from "@inertiajs/react"

import AppLogoIcon from "@/components/app-logo-icon"
import { dashboardPath, signInPath } from "@/routes"
import type { SharedData } from "@/types"

export default function Welcome() {
  const page = usePage<SharedData>()
  const { auth } = page.props

  return (
    <>
      <Head title="Welcome">
        <link rel="preconnect" href="https://fonts.bunny.net" />
        <link
          href="https://fonts.bunny.net/css?family=instrument-sans:400,500,600"
          rel="stylesheet"
        />
      </Head>

      <div className="flex min-h-screen flex-col items-center bg-[#FDFDFC] p-6 text-[#1b1b18] lg:justify-center lg:p-8 dark:bg-[#0a0a0a]">
        <header className="mb-6 w-full max-w-[335px] text-sm not-has-[nav]:hidden lg:max-w-4xl">
          <nav className="flex items-center justify-end gap-4">
            {auth.user ? (
              <Link
                href={dashboardPath()}
                className="inline-block rounded-sm border border-[#19140035] px-5 py-1.5 text-sm leading-normal text-[#1b1b18] hover:border-[#1915014a] dark:border-[#3E3E3A] dark:text-[#EDEDEC] dark:hover:border-[#62605b]"
              >
                Dashboard
              </Link>
            ) : (
              <>
                <Link
                  href={signInPath()}
                  className="inline-block rounded-sm border border-transparent px-5 py-1.5 text-sm leading-normal text-[#1b1b18] hover:border-[#19140035] dark:text-[#EDEDEC] dark:hover:border-[#3E3E3A]"
                >
                  Log in
                </Link>
              </>
            )}
          </nav>
        </header>

        <div className="flex w-full items-center justify-center opacity-100 transition-opacity duration-750 lg:grow starting:opacity-0">
          <main className="flex w-full max-w-[335px] flex-col-reverse lg:max-w-4xl lg:flex-row">
            <div className="flex-1 rounded-br-lg rounded-bl-lg bg-white p-6 pb-12 text-[13px] leading-[20px] shadow-[inset_0px_0px_0px_1px_rgba(26,26,0,0.16)] lg:rounded-tl-lg lg:rounded-br-none lg:p-20 dark:bg-[#161615] dark:text-[#EDEDEC] dark:shadow-[inset_0px_0px_0px_1px_#fffaed2d]">
              <h1 className="mb-1 font-medium">
                {import.meta.env.VITE_APP_NAME ?? "React Starter Kit"}
              </h1>
              <p className="mb-2 text-[#706f6c] dark:text-[#A1A09A]">
                Rails + Inertia.js + React + shadcn/ui
                <br />
                Here are some resources to begin:
              </p>

              <ul className="mb-4 flex flex-col lg:mb-6">
                {[
                  {
                    text: "Inertia Rails Docs",
                    href: "https://inertia-rails.dev",
                  },
                  {
                    text: "shadcn/ui Components",
                    href: "https://ui.shadcn.com",
                  },
                  {
                    text: "React Docs",
                    href: "https://react.dev",
                  },
                  {
                    text: "Rails Guides",
                    href: "https://guides.rubyonrails.org",
                  },
                ].map((resource, index) => (
                  <ResourceItem key={index} {...resource} />
                ))}
              </ul>

              <ul className="flex gap-3 text-sm leading-normal">
                <li>
                  <a
                    href="https://inertia-rails.dev"
                    target="_blank"
                    className="inline-block rounded-sm border border-black bg-[#1b1b18] px-5 py-1.5 text-sm leading-normal text-white hover:border-black hover:bg-black dark:border-[#eeeeec] dark:bg-[#eeeeec] dark:text-[#1C1C1A] dark:hover:border-white dark:hover:bg-white"
                    rel="noreferrer"
                  >
                    Learn More
                  </a>
                </li>
              </ul>
            </div>

            <div className="relative -mb-px aspect-[335/376] w-full shrink-0 overflow-hidden rounded-t-lg bg-[#D30001] p-10 text-white lg:mb-0 lg:-ml-px lg:aspect-auto lg:w-[438px] lg:rounded-t-none lg:rounded-r-lg">
              <AppLogoIcon className="h-full w-full" />
            </div>
          </main>
        </div>
      </div>
    </>
  )
}

function ResourceItem({ text, href }: { text: string; href: string }) {
  return (
    <li className="relative flex items-center gap-4 py-2">
      <span className="flex h-3.5 w-3.5 items-center justify-center rounded-full border border-[#e3e3e0] bg-[#FDFDFC] shadow-[0px_0px_1px_0px_rgba(0,0,0,0.03),0px_1px_2px_0px_rgba(0,0,0,0.06)] dark:border-[#3E3E3A] dark:bg-[#161615]">
        <span className="h-1.5 w-1.5 rounded-full bg-[#dbdbd7] dark:bg-[#3E3E3A]" />
      </span>
      <a
        href={href}
        target="_blank"
        className="inline-flex items-center space-x-1 font-medium text-[#f53003] underline underline-offset-4 dark:text-[#FF4433]"
        rel="noreferrer"
      >
        <span>{text}</span>
        <svg width={10} height={11} viewBox="0 0 10 11" className="h-2.5 w-2.5">
          <path
            d="M7.70833 6.95834V2.79167H3.54167M2.5 8L7.5 3.00001"
            stroke="currentColor"
            strokeLinecap="square"
          />
        </svg>
      </a>
    </li>
  )
}
