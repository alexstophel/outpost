import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input"]

  connect() {
    this.autoResize()
  }

  handleKeydown(event) {
    // Enter without Shift submits the form
    if (event.key === "Enter" && !event.shiftKey) {
      event.preventDefault()
      
      // Only submit if there's content
      if (this.inputTarget.value.trim()) {
        this.element.requestSubmit()
      }
    }
  }

  autoResize() {
    const input = this.inputTarget
    input.style.height = "auto"
    input.style.height = Math.min(input.scrollHeight, 150) + "px"
  }

  reset() {
    this.inputTarget.value = ""
    this.inputTarget.style.height = "auto"
    this.inputTarget.focus()
  }
}
