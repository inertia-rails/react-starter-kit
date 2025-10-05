import { useCallback, useEffect, useRef, useState } from "react"

import type {
  AutocompleteCard,
  SearchCard,
  SearchResponse,
} from "@/lib/types/card"

type SearchMode = "auto" | "keyword" | "semantic" | "hybrid"
type ColorMatchMode = "exact" | "includes"

export interface SearchFilters {
  colors?: string[]
  colorMatch?: ColorMatchMode
  cmcMin?: number
  cmcMax?: number
  keywords?: string[]
  types?: string[]
  formats?: string[]
  rarities?: string[]
  powerMin?: number
  powerMax?: number
  toughnessMin?: number
  toughnessMax?: number
  loyaltyMin?: number
  loyaltyMax?: number
  edhrecRankMin?: number
  edhrecRankMax?: number
  pennyRankMin?: number
  pennyRankMax?: number
  releasedAfter?: string
  releasedBefore?: string
  games?: string[]
  onArena?: boolean
  onMtgo?: boolean
  producedMana?: string[]
  colorIndicator?: string[]
  finishes?: string[]
  artists?: string[]
  sets?: string[]
  frames?: string[]
  borderColors?: string[]
  frameEffects?: string[]
  promoTypes?: string[]
  oversized?: boolean
  promo?: boolean
  reprint?: boolean
  variation?: boolean
  digital?: boolean
  booster?: boolean
  storySpotlight?: boolean
  contentWarning?: boolean
  gameChanger?: boolean
  colorless?: boolean
  monoColor?: boolean
  multicolor?: boolean
  priceUsdMin?: number
  priceUsdMax?: number
  priceUsdFoilMin?: number
  priceUsdFoilMax?: number
  priceEurMin?: number
  priceEurMax?: number
  priceTixMin?: number
  priceTixMax?: number
}

interface UseSearchOptions {
  debounceMs?: number
  autocompleteEnabled?: boolean
  autocompleteTriggerLength?: number
  autocompleteLimit?: number
  searchMode?: SearchMode
  perPage?: number
}

interface UseSearchReturn {
  // State
  query: string
  searchResults: SearchCard[]
  suggestions: AutocompleteCard[]
  isLoading: boolean
  showSuggestions: boolean
  totalResults: number
  currentPage: number
  totalPages: number
  perPage: number
  searchMode: SearchMode
  filters: SearchFilters

  // Actions
  setQuery: (query: string) => void
  handleSearch: (searchQuery?: string, page?: number) => Promise<void>
  handleSuggestionClick: (cardName: string) => void
  setShowSuggestions: (show: boolean) => void
  clearSearch: () => void
  updateFilters: (newFilters: Partial<SearchFilters>) => void
  removeFilter: (filterKey: keyof SearchFilters) => void
  clearFilters: () => void
  goToPage: (page: number) => void
  nextPage: () => void
  prevPage: () => void
}

export function useSearch(options: UseSearchOptions = {}): UseSearchReturn {
  const {
    debounceMs = 300,
    autocompleteEnabled = false,
    autocompleteTriggerLength = 2,
    autocompleteLimit = 10,
    searchMode = "auto",
    perPage = 20,
  } = options

  const [query, setQuery] = useState("")
  const [suggestions, setSuggestions] = useState<AutocompleteCard[]>([])
  const [searchResults, setSearchResults] = useState<SearchCard[]>([])
  const [isLoading, setIsLoading] = useState(false)
  const [showSuggestions, setShowSuggestions] = useState(false)
  const [totalResults, setTotalResults] = useState(0)
  const [currentPage, setCurrentPage] = useState(1)
  const [totalPages, setTotalPages] = useState(0)
  const [filters, setFilters] = useState<SearchFilters>({})

  const debounceTimeout = useRef<ReturnType<typeof setTimeout> | undefined>(
    undefined
  )

  // Autocomplete effect
  useEffect(() => {
    if (debounceTimeout.current !== undefined) {
      clearTimeout(debounceTimeout.current)
    }

    if (query.length < autocompleteTriggerLength || !autocompleteEnabled) {
      setSuggestions([])
      setShowSuggestions(false)
      return
    }

    debounceTimeout.current = setTimeout(() => {
      fetch(
        `/api/cards/autocomplete?q=${encodeURIComponent(query)}&limit=${autocompleteLimit}`
      )
        .then((res) => res.json())
        .then((data: AutocompleteCard[]) => {
          setSuggestions(data)
          setShowSuggestions(true)
        })
        .catch((error: unknown) => {
          console.error("Autocomplete error:", error)
          setSuggestions([])
        })
    }, debounceMs)

    return () => {
      if (debounceTimeout.current) {
        clearTimeout(debounceTimeout.current)
      }
    }
  }, [query, autocompleteTriggerLength, autocompleteLimit, debounceMs])

  // Build query params from filters
  const buildFilterParams = useCallback((activeFilters: SearchFilters) => {
    const params = new URLSearchParams()

    if (activeFilters.colors && activeFilters.colors.length > 0) {
      activeFilters.colors.forEach((color) => params.append("colors[]", color))
      if (activeFilters.colorMatch) {
        params.append("color_match", activeFilters.colorMatch)
      }
    }

    if (activeFilters.cmcMin !== undefined) {
      params.append("cmc_min", activeFilters.cmcMin.toString())
    }

    if (activeFilters.cmcMax !== undefined) {
      params.append("cmc_max", activeFilters.cmcMax.toString())
    }

    if (activeFilters.keywords && activeFilters.keywords.length > 0) {
      activeFilters.keywords.forEach((keyword) =>
        params.append("keywords[]", keyword)
      )
    }

    if (activeFilters.types && activeFilters.types.length > 0) {
      activeFilters.types.forEach((type) => params.append("types[]", type))
    }

    if (activeFilters.formats && activeFilters.formats.length > 0) {
      activeFilters.formats.forEach((format) =>
        params.append("formats[]", format)
      )
    }

    if (activeFilters.rarities && activeFilters.rarities.length > 0) {
      activeFilters.rarities.forEach((rarity) =>
        params.append("rarities[]", rarity)
      )
    }

    if (activeFilters.powerMin !== undefined) {
      params.append("power_min", activeFilters.powerMin.toString())
    }

    if (activeFilters.powerMax !== undefined) {
      params.append("power_max", activeFilters.powerMax.toString())
    }

    if (activeFilters.toughnessMin !== undefined) {
      params.append("toughness_min", activeFilters.toughnessMin.toString())
    }

    if (activeFilters.toughnessMax !== undefined) {
      params.append("toughness_max", activeFilters.toughnessMax.toString())
    }

    if (activeFilters.loyaltyMin !== undefined) {
      params.append("loyalty_min", activeFilters.loyaltyMin.toString())
    }

    if (activeFilters.loyaltyMax !== undefined) {
      params.append("loyalty_max", activeFilters.loyaltyMax.toString())
    }

    if (activeFilters.edhrecRankMin !== undefined) {
      params.append("edhrec_rank_min", activeFilters.edhrecRankMin.toString())
    }

    if (activeFilters.edhrecRankMax !== undefined) {
      params.append("edhrec_rank_max", activeFilters.edhrecRankMax.toString())
    }

    if (activeFilters.pennyRankMin !== undefined) {
      params.append("penny_rank_min", activeFilters.pennyRankMin.toString())
    }

    if (activeFilters.pennyRankMax !== undefined) {
      params.append("penny_rank_max", activeFilters.pennyRankMax.toString())
    }

    if (activeFilters.releasedAfter) {
      params.append("released_after", activeFilters.releasedAfter)
    }

    if (activeFilters.releasedBefore) {
      params.append("released_before", activeFilters.releasedBefore)
    }

    if (activeFilters.games && activeFilters.games.length > 0) {
      activeFilters.games.forEach((game) => params.append("games[]", game))
    }

    if (activeFilters.onArena !== undefined) {
      params.append("on_arena", activeFilters.onArena.toString())
    }

    if (activeFilters.onMtgo !== undefined) {
      params.append("on_mtgo", activeFilters.onMtgo.toString())
    }

    if (activeFilters.producedMana && activeFilters.producedMana.length > 0) {
      activeFilters.producedMana.forEach((mana) =>
        params.append("produced_mana[]", mana)
      )
    }

    if (activeFilters.colorIndicator && activeFilters.colorIndicator.length > 0) {
      activeFilters.colorIndicator.forEach((color) =>
        params.append("color_indicator[]", color)
      )
    }

    if (activeFilters.finishes && activeFilters.finishes.length > 0) {
      activeFilters.finishes.forEach((finish) =>
        params.append("finishes[]", finish)
      )
    }

    if (activeFilters.artists && activeFilters.artists.length > 0) {
      activeFilters.artists.forEach((artist) =>
        params.append("artists[]", artist)
      )
    }

    if (activeFilters.sets && activeFilters.sets.length > 0) {
      activeFilters.sets.forEach((set) => params.append("sets[]", set))
    }

    if (activeFilters.frames && activeFilters.frames.length > 0) {
      activeFilters.frames.forEach((frame) => params.append("frames[]", frame))
    }

    if (activeFilters.borderColors && activeFilters.borderColors.length > 0) {
      activeFilters.borderColors.forEach((color) =>
        params.append("border_colors[]", color)
      )
    }

    if (activeFilters.frameEffects && activeFilters.frameEffects.length > 0) {
      activeFilters.frameEffects.forEach((effect) =>
        params.append("frame_effects[]", effect)
      )
    }

    if (activeFilters.promoTypes && activeFilters.promoTypes.length > 0) {
      activeFilters.promoTypes.forEach((type) =>
        params.append("promo_types[]", type)
      )
    }

    if (activeFilters.oversized !== undefined) {
      params.append("oversized", activeFilters.oversized.toString())
    }

    if (activeFilters.promo !== undefined) {
      params.append("promo", activeFilters.promo.toString())
    }

    if (activeFilters.reprint !== undefined) {
      params.append("reprint", activeFilters.reprint.toString())
    }

    if (activeFilters.variation !== undefined) {
      params.append("variation", activeFilters.variation.toString())
    }

    if (activeFilters.digital !== undefined) {
      params.append("digital", activeFilters.digital.toString())
    }

    if (activeFilters.booster !== undefined) {
      params.append("booster", activeFilters.booster.toString())
    }

    if (activeFilters.storySpotlight !== undefined) {
      params.append("story_spotlight", activeFilters.storySpotlight.toString())
    }

    if (activeFilters.contentWarning !== undefined) {
      params.append("content_warning", activeFilters.contentWarning.toString())
    }

    if (activeFilters.gameChanger !== undefined) {
      params.append("game_changer", activeFilters.gameChanger.toString())
    }

    if (activeFilters.colorless !== undefined) {
      params.append("colorless", activeFilters.colorless.toString())
    }

    if (activeFilters.monoColor !== undefined) {
      params.append("mono_color", activeFilters.monoColor.toString())
    }

    if (activeFilters.multicolor !== undefined) {
      params.append("multicolor", activeFilters.multicolor.toString())
    }

    if (activeFilters.priceUsdMin !== undefined) {
      params.append("price_usd_min", activeFilters.priceUsdMin.toString())
    }

    if (activeFilters.priceUsdMax !== undefined) {
      params.append("price_usd_max", activeFilters.priceUsdMax.toString())
    }

    if (activeFilters.priceUsdFoilMin !== undefined) {
      params.append("price_usd_foil_min", activeFilters.priceUsdFoilMin.toString())
    }

    if (activeFilters.priceUsdFoilMax !== undefined) {
      params.append("price_usd_foil_max", activeFilters.priceUsdFoilMax.toString())
    }

    if (activeFilters.priceEurMin !== undefined) {
      params.append("price_eur_min", activeFilters.priceEurMin.toString())
    }

    if (activeFilters.priceEurMax !== undefined) {
      params.append("price_eur_max", activeFilters.priceEurMax.toString())
    }

    if (activeFilters.priceTixMin !== undefined) {
      params.append("price_tix_min", activeFilters.priceTixMin.toString())
    }

    if (activeFilters.priceTixMax !== undefined) {
      params.append("price_tix_max", activeFilters.priceTixMax.toString())
    }

    return params
  }, [])

  // Search function
  const handleSearch = useCallback(
    async (searchQuery?: string, page?: number) => {
      const finalQuery = searchQuery ?? query
      const finalPage = page ?? currentPage

      // Check if we have either a query or active filters
      const hasFilters = Object.keys(filters).some((key) => {
        const value = filters[key as keyof SearchFilters]
        if (Array.isArray(value)) {
          return value.length > 0
        }
        return value !== undefined && value !== null
      })

      if (!finalQuery.trim() && !hasFilters) {
        setSearchResults([])
        setTotalResults(0)
        setCurrentPage(1)
        setTotalPages(0)
        return
      }

      setIsLoading(true)
      setShowSuggestions(false)

      try {
        const params = buildFilterParams(filters)
        if (finalQuery.trim()) {
          params.append("q", finalQuery)
        }
        params.append("search_mode", searchMode)
        params.append("page", finalPage.toString())
        params.append("per_page", perPage.toString())

        const response = await fetch(`/api/cards/search?${params.toString()}`)
        const data = (await response.json()) as SearchResponse
        setSearchResults(data.results)
        setTotalResults(data.total)
        setCurrentPage(data.page)
        setTotalPages(data.total_pages)
      } catch (error: unknown) {
        console.error("Search error:", error)
        setSearchResults([])
        setTotalResults(0)
        setCurrentPage(1)
        setTotalPages(0)
      } finally {
        setIsLoading(false)
      }
    },
    [query, currentPage, searchMode, filters, perPage, buildFilterParams]
  )

  // Handle suggestion click
  const handleSuggestionClick = useCallback(
    (cardName: string) => {
      setQuery(cardName)
      setShowSuggestions(false)
      void handleSearch(cardName)
    },
    [handleSearch]
  )

  // Clear search
  const clearSearch = useCallback(() => {
    setQuery("")
    setSearchResults([])
    setSuggestions([])
    setTotalResults(0)
    setCurrentPage(1)
    setTotalPages(0)
    setShowSuggestions(false)
  }, [])

  // Update filters
  const updateFilters = useCallback((newFilters: Partial<SearchFilters>) => {
    setFilters((prev) => ({ ...prev, ...newFilters }))
    // Reset to page 1 when filters change
    setCurrentPage(1)
  }, [])

  // Remove a specific filter
  const removeFilter = useCallback((filterKey: keyof SearchFilters) => {
    setFilters((prev) => {
      const updated = { ...prev }
      delete updated[filterKey]
      return updated
    })
    // Reset to page 1 when filters change
    setCurrentPage(1)
  }, [])

  // Clear all filters
  const clearFilters = useCallback(() => {
    setFilters({})
    // Reset to page 1 when filters are cleared
    setCurrentPage(1)
  }, [])

  // Pagination navigation
  const goToPage = useCallback(
    (page: number) => {
      if (page >= 1 && page <= totalPages && page !== currentPage) {
        void handleSearch(undefined, page)
      }
    },
    [currentPage, totalPages, handleSearch]
  )

  const nextPage = useCallback(() => {
    if (currentPage < totalPages) {
      void handleSearch(undefined, currentPage + 1)
    }
  }, [currentPage, totalPages, handleSearch])

  const prevPage = useCallback(() => {
    if (currentPage > 1) {
      void handleSearch(undefined, currentPage - 1)
    }
  }, [currentPage, handleSearch])

  return {
    // State
    query,
    searchResults,
    suggestions,
    isLoading,
    showSuggestions,
    totalResults,
    currentPage,
    totalPages,
    perPage,
    searchMode,
    filters,

    // Actions
    setQuery,
    handleSearch,
    handleSuggestionClick,
    setShowSuggestions,
    clearSearch,
    updateFilters,
    removeFilter,
    clearFilters,
    goToPage,
    nextPage,
    prevPage,
  }
}
