import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dropdown", "membersList", "addMemberInput", "addMemberResults", "removeMemberDialog", "removeMemberName", "removeMemberForm"]

  connect() {
    this.isOpen = false
    this.pendingRemoval = null
  }

  toggle() {
    if (this.isOpen) {
      this.close()
    } else {
      this.open()
    }
  }

  open() {
    this.dropdownTarget.classList.remove("hidden")
    this.isOpen = true
    
    // Close when clicking outside
    setTimeout(() => {
      document.addEventListener("click", this.handleOutsideClick)
    }, 0)
    
    document.addEventListener("keydown", this.handleEscape)
  }

  close() {
    this.dropdownTarget.classList.add("hidden")
    this.isOpen = false
    
    if (this.hasAddMemberInputTarget) {
      this.addMemberInputTarget.value = ""
    }
    if (this.hasAddMemberResultsTarget) {
      this.addMemberResultsTarget.classList.add("hidden")
    }
    
    document.removeEventListener("click", this.handleOutsideClick)
    document.removeEventListener("keydown", this.handleEscape)
  }

  handleOutsideClick = (event) => {
    if (!this.dropdownTarget.contains(event.target) && 
        !event.target.closest('[data-action*="room-settings#toggle"]')) {
      this.close()
    }
  }

  handleEscape = (event) => {
    if (event.key === "Escape") {
      this.close()
    }
  }

  async searchUsers() {
    const query = this.addMemberInputTarget.value.trim()

    if (query.length === 0) {
      this.addMemberResultsTarget.classList.add("hidden")
      return
    }

    try {
      const response = await fetch(`/user_searches?q=${encodeURIComponent(query)}`, {
        headers: { "Accept": "application/json" }
      })

      if (response.ok) {
        const users = await response.json()
        this.renderSearchResults(users)
      }
    } catch (error) {
      console.error("Search failed:", error)
    }
  }

  renderSearchResults(users) {
    if (users.length === 0) {
      this.addMemberResultsTarget.innerHTML = `
        <div class="px-3 py-2 text-xs text-neutral-500 italic">No users found</div>
      `
    } else {
      this.addMemberResultsTarget.innerHTML = users.map(user => `
        <button
          type="button"
          class="w-full flex items-center gap-2 px-3 py-2 text-left hover:bg-neutral-700 transition-colors bg-neutral-800"
          data-action="click->room-settings#addMember"
          data-user-id="${user.id}"
          data-user-name="${this.escapeHtml(user.name)}"
        >
          ${user.avatar_url
            ? `<img src="${user.avatar_url}" class="w-5 h-5 object-cover flex-shrink-0 border border-neutral-600">`
            : `<div class="w-5 h-5 bg-neutral-700 border border-neutral-600 flex items-center justify-center text-neutral-400 text-[10px] flex-shrink-0">${user.name.charAt(0).toUpperCase()}</div>`
          }
          <span class="text-xs text-neutral-200">${this.escapeHtml(user.name)}</span>
        </button>
      `).join("")
    }
    this.addMemberResultsTarget.classList.remove("hidden")
  }

  async addMember(event) {
    const userId = event.currentTarget.dataset.userId
    const userName = event.currentTarget.dataset.userName
    const roomId = this.getRoomId()

    try {
      const response = await fetch(`/rooms/${roomId}/memberships`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content
        },
        body: JSON.stringify({ user_id: userId })
      })

      if (response.ok) {
        // Reload the page to show updated member list
        window.location.reload()
      } else if (response.status === 422) {
        // User already a member
        this.addMemberInputTarget.value = ""
        this.addMemberResultsTarget.classList.add("hidden")
      }
    } catch (error) {
      console.error("Failed to add member:", error)
    }
  }

  confirmRemoveMember(event) {
    const membershipId = event.currentTarget.dataset.membershipId
    const userName = event.currentTarget.dataset.userName
    const roomId = this.getRoomId()

    // Store pending removal info
    this.pendingRemoval = { membershipId, roomId }

    // Update modal content
    this.removeMemberNameTarget.textContent = userName
    this.removeMemberFormTarget.action = `/rooms/${roomId}/memberships/${membershipId}`

    // Open the dialog
    this.removeMemberDialogTarget.showModal()
  }

  closeRemoveMemberDialog() {
    this.removeMemberDialogTarget.close()
    this.pendingRemoval = null
  }

  closeRemoveMemberOnBackdropClick(event) {
    if (event.target === this.removeMemberDialogTarget) {
      this.closeRemoveMemberDialog()
    }
  }

  getRoomId() {
    // Extract room ID from the current URL
    const match = window.location.pathname.match(/\/rooms\/(\d+)/)
    return match ? match[1] : null
  }

  escapeHtml(text) {
    const div = document.createElement("div")
    div.textContent = text
    return div.innerHTML
  }
}
