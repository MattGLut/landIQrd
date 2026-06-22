import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "trigger",
    "menu",
    "chevron",
    "label",
    "dialog",
    "dialogTitle",
    "dialogDescription",
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
    this.submitMode = null
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
    const button = event.currentTarget
    const value = button.dataset.status

    this.closeMenuPanel()

    if (value === this.currentStatusValue) return

    if (value === "cancelled" || value === "closed") {
      this.submitMode = button.dataset.submitMode || (this.closeOnlyValue ? "close" : "patch-cancel")
      this.updateDialog(button)
      this.reasonTarget.value = ""
      this.dialogTarget.showModal()
      return
    }

    this.submitStatus(value)
  }

  updateDialog(button) {
    if (button.dataset.dialogTitle && this.hasDialogTitleTarget) {
      this.dialogTitleTarget.textContent = button.dataset.dialogTitle
    }

    if (button.dataset.dialogDescription && this.hasDialogDescriptionTarget) {
      this.dialogDescriptionTarget.textContent = button.dataset.dialogDescription
    }

    const reasonRequired = button.dataset.reasonRequired === "true" || this.closeOnlyValue
    this.reasonTarget.required = reasonRequired
  }

  confirm(event) {
    event.preventDefault()

    const reason = this.reasonTarget.value.trim()
    const mode = this.submitMode || (this.closeOnlyValue ? "close" : "patch-cancel")
    const reasonRequired = mode === "close" || this.reasonTarget.required

    if (reasonRequired && reason === "") {
      this.reasonTarget.focus()
      return
    }

    if (mode === "close") {
      this.closeReasonFieldTarget.value = reason
      this.closeFormTarget.requestSubmit()
    } else {
      this.statusFieldTarget.value = "cancelled"
      this.closureFieldTarget.value = reason
      this.statusFormTarget.requestSubmit()
    }

    this.dialogTarget.close()
    this.submitMode = null
  }

  cancel(event) {
    event.preventDefault()
    this.dialogTarget.close()
    this.submitMode = null
  }

  submitStatus(status) {
    this.statusFieldTarget.value = status
    this.closureFieldTarget.value = ""
    this.statusFormTarget.requestSubmit()
  }
}
