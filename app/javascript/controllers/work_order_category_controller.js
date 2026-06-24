import { Controller } from "@hotwired/stimulus"

const BASE_CATEGORIES = [
  "plumbing", "electrical", "hvac", "appliance", "pest", "general", "other"
]
const COMMERCIAL_CATEGORIES = [
  "fire_safety", "signage", "accessibility", "structural"
]
const UNDEVELOPED_CATEGORIES = [
  "site_maintenance", "fencing", "utilities", "grading", "environmental"
]

export default class extends Controller {
  static targets = ["unitSelect", "categorySelect"]

  static values = {
    unitTypes: Object
  }

  connect() {
    if (this.hasUnitSelectTarget) {
      this.unitSelectTarget.addEventListener("change", this.updateCategories.bind(this))
      this.updateCategories()
    }
  }

  updateCategories() {
    if (!this.hasUnitSelectTarget || !this.hasCategorySelectTarget) return

    const unitId = this.unitSelectTarget.value
    const effectiveType = this.unitTypesValue[unitId] || "residential"
    const allowed = this.categoriesFor(effectiveType)
    const current = this.categorySelectTarget.value

    Array.from(this.categorySelectTarget.options).forEach((option) => {
      if (option.value === "") return
      const visible = allowed.includes(option.value)
      option.hidden = !visible
      option.disabled = !visible
    })

    if (!allowed.includes(current)) {
      this.categorySelectTarget.value = allowed.includes("general") ? "general" : allowed[0]
    }
  }

  categoriesFor(type) {
    const categories = [...BASE_CATEGORIES]
    if (type === "commercial") {
      categories.push(...COMMERCIAL_CATEGORIES)
    } else if (type === "undeveloped") {
      categories.push(...UNDEVELOPED_CATEGORIES)
    }
    return categories
  }
}
