import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { roomId: Number }

  connect() {
    this.scrollToBottom()
    this.observeNewMessages()
  }

  disconnect() {
    if (this.observer) {
      this.observer.disconnect()
    }
  }

  scrollToBottom() {
    this.element.scrollTop = this.element.scrollHeight
  }

  isNearBottom() {
    const threshold = 100
    return this.element.scrollHeight - this.element.scrollTop - this.element.clientHeight < threshold
  }

  observeNewMessages() {
    const messagesContainer = this.element.querySelector("#messages")
    if (!messagesContainer) return

    this.observer = new MutationObserver((mutations) => {
      for (const mutation of mutations) {
        if (mutation.type === "childList" && mutation.addedNodes.length > 0) {
          // Only auto-scroll if user is near bottom
          if (this.isNearBottom()) {
            this.scrollToBottom()
          }
        }
      }
    })

    this.observer.observe(messagesContainer, { childList: true })
  }
}
