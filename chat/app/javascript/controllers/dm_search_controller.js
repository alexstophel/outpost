import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "input", "results"]
  
  connect() {
    this.selectedIndex = -1
    this.users = []
  }
  
  open() {
    this.modalTarget.classList.remove("hidden")
    this.inputTarget.value = ""
    this.resultsTarget.innerHTML = ""
    this.selectedIndex = -1
    this.users = []
    
    // Focus input after a brief delay for animation
    requestAnimationFrame(() => {
      this.inputTarget.focus()
    })
    
    // Listen for escape key
    document.addEventListener("keydown", this.handleEscape)
  }
  
  close() {
    this.modalTarget.classList.add("hidden")
    this.inputTarget.value = ""
    this.resultsTarget.innerHTML = ""
    document.removeEventListener("keydown", this.handleEscape)
  }
  
  handleEscape = (event) => {
    if (event.key === "Escape") {
      this.close()
    }
  }
  
  async search() {
    const query = this.inputTarget.value.trim()
    
    if (query.length === 0) {
      this.resultsTarget.innerHTML = ""
      this.users = []
      this.selectedIndex = -1
      return
    }
    
    try {
      const response = await fetch(`/user_searches?q=${encodeURIComponent(query)}`, {
        headers: {
          "Accept": "application/json"
        }
      })
      
      if (response.ok) {
        this.users = await response.json()
        this.selectedIndex = -1
        this.renderResults()
      }
    } catch (error) {
      console.error("Search failed:", error)
    }
  }
  
  renderResults() {
    if (this.users.length === 0) {
      this.resultsTarget.innerHTML = `
        <div class="px-4 py-3 text-sm text-neutral-500 italic">
          No users found
        </div>
      `
      return
    }
    
    this.resultsTarget.innerHTML = this.users.map((user, index) => `
      <button
        type="button"
        class="w-full flex items-center gap-3 px-4 py-3 text-left hover:bg-neutral-800 transition-colors ${index === this.selectedIndex ? 'bg-neutral-800' : ''}"
        data-action="click->dm-search#selectUser"
        data-user-id="${user.id}"
      >
        ${user.avatar_url 
          ? `<img src="${user.avatar_url}" class="w-8 h-8 object-cover flex-shrink-0 border border-neutral-600">`
          : `<div class="w-8 h-8 bg-neutral-700 border border-neutral-600 flex items-center justify-center text-neutral-400 text-xs flex-shrink-0">${user.name.charAt(0).toUpperCase()}</div>`
        }
        <span class="text-sm text-neutral-200">${this.escapeHtml(user.name)}</span>
      </button>
    `).join("")
  }
  
  handleKeydown(event) {
    if (this.users.length === 0) return
    
    switch (event.key) {
      case "ArrowDown":
        event.preventDefault()
        this.selectedIndex = Math.min(this.selectedIndex + 1, this.users.length - 1)
        this.renderResults()
        break
      case "ArrowUp":
        event.preventDefault()
        this.selectedIndex = Math.max(this.selectedIndex - 1, 0)
        this.renderResults()
        break
      case "Enter":
        event.preventDefault()
        if (this.selectedIndex >= 0) {
          this.startConversation(this.users[this.selectedIndex].id)
        } else if (this.users.length === 1) {
          this.startConversation(this.users[0].id)
        }
        break
    }
  }
  
  selectUser(event) {
    const userId = event.currentTarget.dataset.userId
    this.startConversation(userId)
  }
  
  startConversation(userId) {
    // Create a form and submit it
    const form = document.createElement("form")
    form.method = "POST"
    form.action = "/direct_messages"
    
    const csrfToken = document.querySelector("meta[name='csrf-token']").content
    const csrfInput = document.createElement("input")
    csrfInput.type = "hidden"
    csrfInput.name = "authenticity_token"
    csrfInput.value = csrfToken
    
    const userIdInput = document.createElement("input")
    userIdInput.type = "hidden"
    userIdInput.name = "user_id"
    userIdInput.value = userId
    
    form.appendChild(csrfInput)
    form.appendChild(userIdInput)
    document.body.appendChild(form)
    form.submit()
  }
  
  escapeHtml(text) {
    const div = document.createElement("div")
    div.textContent = text
    return div.innerHTML
  }
}
