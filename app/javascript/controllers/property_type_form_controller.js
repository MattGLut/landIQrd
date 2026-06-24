import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "typeSelect",
    "featureSection",
    "scalarSection",
    "sizeSection",
    "typeHint",
    "propertyType"
  ]

  static values = {
    mode: { type: String, default: "property" },
    propertyType: String
  }

  connect() {
    this.updateVisibility()
  }

  typeChanged() {
    this.updateVisibility()
  }

  updateVisibility() {
    const type = this.effectiveType()

    this.featureSectionTargets.forEach((section) => {
      section.classList.toggle("hidden", section.dataset.type !== type)
    })

    this.scalarSectionTargets.forEach((section) => {
      section.classList.toggle("hidden", section.dataset.type !== type)
    })

    if (this.hasSizeSectionTarget) {
      const showSize = type === "residential" || type === "commercial"
      this.sizeSectionTarget.classList.toggle("hidden", !showSize)
    }

    if (this.hasTypeHintTarget) {
      this.typeHintTarget.textContent = this.hintFor(type)
    }
  }

  effectiveType() {
    if (this.modeValue === "unit") {
      const override = this.typeSelectTarget.value
      if (override) return override
      return this.propertyTypeValue
    }

    return this.typeSelectTarget.value
  }

  hintFor(type) {
    const hints = {
      residential: "Residential properties typically have apartment or house-style units.",
      commercial: "Commercial properties typically have suite-style units.",
      undeveloped: "Undeveloped land is tracked by acreage, zoning, and utility access."
    }
    return hints[type] || ""
  }
}
