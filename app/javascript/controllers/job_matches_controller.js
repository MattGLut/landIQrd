import { Controller } from "@hotwired/stimulus"

// Reloads the "Matching contractors" Turbo Frame when the property or trades change.
export default class extends Controller {
  static targets = ["frame"]
  static values = { url: String }

  disconnect() {
    clearTimeout(this._timer)
  }

  refresh() {
    clearTimeout(this._timer)
    this._timer = setTimeout(() => this._load(), 200)
  }

  _load() {
    const form = this.element.querySelector("form")
    if (!form || !this.hasFrameTarget) return

    const params = new URLSearchParams()
    const property = form.querySelector("[name='job[property_id]']")
    if (property && property.value) params.set("property_id", property.value)
    form.querySelectorAll("input[name='job[trades][]']:checked").forEach((box) => {
      params.append("trades[]", box.value)
    })

    this.frameTarget.src = `${this.urlValue}?${params.toString()}`
  }
}
