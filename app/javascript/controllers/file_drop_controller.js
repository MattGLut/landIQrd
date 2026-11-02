import { Controller } from "@hotwired/stimulus"

// Drag-and-drop file zone that mirrors the native file input and lists chosen files.
export default class extends Controller {
  static targets = ["input", "zone", "list"]

  browse(event) {
    event.preventDefault()
    this.inputTarget.click()
  }

  dragover(event) {
    event.preventDefault()
    this.zoneTarget.classList.add("border-brand-400", "bg-brand-50")
  }

  dragleave() {
    this.zoneTarget.classList.remove("border-brand-400", "bg-brand-50")
  }

  drop(event) {
    event.preventDefault()
    this.dragleave()
    if (event.dataTransfer?.files?.length) {
      this.inputTarget.files = event.dataTransfer.files
      this.render()
    }
  }

  render() {
    if (!this.hasListTarget) return

    const files = Array.from(this.inputTarget.files)
    this.listTarget.innerHTML = ""
    files.forEach((file) => {
      const item = document.createElement("li")
      const size = file.size >= 1048576 ? `${(file.size / 1048576).toFixed(1)} MB` : `${Math.max(1, Math.round(file.size / 1024))} KB`
      item.textContent = `${file.name} (${size})`
      this.listTarget.appendChild(item)
    })
  }
}
