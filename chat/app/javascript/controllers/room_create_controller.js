import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "nameInput", "searchInput", "searchResults", "selectedMembers"]

  connect() {
    this.selectedUsers = []
  }

  open() {
    this.modalTarget.classList.remove("hidden")
    this.nameInputTarget.value = ""
    this.searchInputTarget.value = ""
    this.searchResultsTarget.innerHTML = ""
    this.searchResultsTarget.classList.add("hidden")
    this.selectedMembers = []
    this.selectedUsers = []
    this.renderSelectedMembers()

    requestAnimationFrame(() => {
      this.nameInputTarget.focus()
    })

    document.addEventListener("keydown", this.handleEscape)
  }

  close() {
    this.modalTarget.classList.add("hidden")
    document.removeEventListener("keydown", this.handleEscape)
  }

  handleEscape = (event) => {
    if (event.key === "Escape") {
      this.close()
    }
  }

  async searchUsers() {
    const query = this.searchInputTarget.value.trim()

    if (query.length === 0) {
      this.searchResultsTarget.classList.add("hidden")
      return
    }

    try {
      const response = await fetch(`/user_searches?q=${encodeURIComponent(query)}`, {
        headers: { "Accept": "application/json" }
      })

      if (response.ok) {
        const users = await response.json()
        // Filter out already selected users
        const selectedIds = this.selectedUsers.map(u => u.id)
        const availableUsers = users.filter(u => !selectedIds.includes(u.id))
        this.renderSearchResults(availableUsers)
      }
    } catch (error) {
      console.error("Search failed:", error)
    }
  }

  renderSearchResults(users) {
    if (users.length === 0) {
      this.searchResultsTarget.innerHTML = `
        <div class="px-3 py-2 text-sm text-neutral-500 italic">No users found</div>
      `
    } else {
      this.searchResultsTarget.innerHTML = users.map(user => `
        <button
          type="button"
          class="w-full flex items-center gap-2 px-3 py-2 text-left hover:bg-neutral-700 transition-colors"
          data-action="click->room-create#addUser"
          data-user-id="${user.id}"
          data-user-name="${this.escapeHtml(user.name)}"
        >
          ${user.avatar_url
            ? `<img src="${user.avatar_url}" class="w-6 h-6 object-cover flex-shrink-0 border border-neutral-600">`
            : `<div class="w-6 h-6 bg-neutral-700 border border-neutral-600 flex items-center justify-center text-neutral-400 text-[10px] flex-shrink-0">${user.name.charAt(0).toUpperCase()}</div>`
          }
          <span class="text-sm text-neutral-200">${this.escapeHtml(user.name)}</span>
        </button>
      `).join("")
    }
    this.searchResultsTarget.classList.remove("hidden")
  }

  addUser(event) {
    const userId = parseInt(event.currentTarget.dataset.userId)
    const userName = event.currentTarget.dataset.userName

    if (!this.selectedUsers.find(u => u.id === userId)) {
      this.selectedUsers.push({ id: userId, name: userName })
      this.renderSelectedMembers()
    }

    this.searchInputTarget.value = ""
    this.searchResultsTarget.classList.add("hidden")
  }

  removeUser(event) {
    const userId = parseInt(event.currentTarget.dataset.userId)
    this.selectedUsers = this.selectedUsers.filter(u => u.id !== userId)
    this.renderSelectedMembers()
  }

  renderSelectedMembers() {
    if (this.selectedUsers.length === 0) {
      this.selectedMembersTarget.innerHTML = ""
      return
    }

    this.selectedMembersTarget.innerHTML = this.selectedUsers.map(user => `
      <span class="inline-flex items-center gap-1 px-2 py-1 bg-neutral-800 border border-neutral-700 text-sm text-neutral-300">
        ${this.escapeHtml(user.name)}
        <button
          type="button"
          class="text-neutral-500 hover:text-neutral-300"
          data-action="click->room-create#removeUser"
          data-user-id="${user.id}"
        >
          <svg xmlns="http://www.w3.org/2000/svg" class="h-3 w-3" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
            <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
          </svg>
        </button>
        <input type="hidden" name="member_ids[]" value="${user.id}">
      </span>
    `).join("")
  }

  submit(event) {
    // Form will submit naturally, just close the modal
    this.close()
  }

  escapeHtml(text) {
    const div = document.createElement("div")
    div.textContent = text
    return div.innerHTML
  }
}
