import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "trigger",
    "menu",
    "chevron",
    "label",
    "dialog",
    "reason",
    "statusForm",
    "statusField",
    "closureField",
    "closeForm",
    "closeReasonField"
  ]

  static values = {
    currentStatus: String,
    closeOnly: Boolean
  }

  connect() {
    this.closeMenu = this.closeMenu.bind(this)
  }

  disconnect() {
    document.removeEventListener("click", this.closeMenu)
  }

  toggleMenu(event) {
    event.stopPropagation()

    if (this.menuTarget.classList.contains("hidden")) {
      this.openMenu()
    } else {
      this.closeMenuPanel()
    }
  }

  openMenu() {
    this.menuTarget.classList.remove("hidden")
    this.triggerTarget.setAttribute("aria-expanded", "true")
    this.chevronTarget.classList.add("rotate-180")
    document.addEventListener("click", this.closeMenu)
  }

  closeMenuPanel() {
    this.menuTarget.classList.add("hidden")
    this.triggerTarget.setAttribute("aria-expanded", "false")
    this.chevronTarget.classList.remove("rotate-180")
    document.removeEventListener("click", this.closeMenu)
  }

  closeMenu(event) {
    if (!this.element.contains(event.target)) {
      this.closeMenuPanel()
    }
  }

  handleKeydown(event) {
    if (event.key === "Escape") {
      this.closeMenuPanel()
    }
  }

  chooseOption(event) {
    event.preventDefault()
    const value = event.currentTarget.dataset.status

    this.closeMenuPanel()

    if (value === this.currentStatusValue) return

    if (value === "cancelled") {
      this.reasonTarget.value = ""
      this.dialogTarget.showModal()
      return
    }

    this.submitStatus(value)
  }

  confirm(event) {
    event.preventDefault()

    const reason = this.reasonTarget.value.trim()
    if (this.closeOnlyValue && reason === "") {
      this.reasonTarget.focus()
      return
    }

    if (this.closeOnlyValue) {
      this.closeReasonFieldTarget.value = reason
      this.closeFormTarget.requestSubmit()
    } else {
      this.statusFieldTarget.value = "cancelled"
      this.closureFieldTarget.value = reason
      this.statusFormTarget.requestSubmit()
    }

    this.dialogTarget.close()
  }

  cancel(event) {
    event.preventDefault()
    this.dialogTarget.close()
  }

  submitStatus(status) {
    this.statusFieldTarget.value = status
    this.closureFieldTarget.value = ""
    this.statusFormTarget.requestSubmit()
  }
}
