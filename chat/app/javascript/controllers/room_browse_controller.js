import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "searchInput", "roomList"]

  connect() {
    this.rooms = []
  }

  async open() {
    this.modalTarget.classList.remove("hidden")
    this.searchInputTarget.value = ""
    this.roomListTarget.innerHTML = `<div class="px-4 py-3 text-sm text-neutral-500 italic">Loading...</div>`

    requestAnimationFrame(() => {
      this.searchInputTarget.focus()
    })

    document.addEventListener("keydown", this.handleEscape)

    // Load available rooms
    await this.loadRooms()
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

  async loadRooms() {
    try {
      const response = await fetch("/rooms", {
        headers: { "Accept": "application/json" }
      })

      if (response.ok) {
        this.rooms = await response.json()
        this.renderRooms(this.rooms)
      }
    } catch (error) {
      console.error("Failed to load rooms:", error)
      this.roomListTarget.innerHTML = `<div class="px-4 py-3 text-sm text-red-400">Failed to load rooms</div>`
    }
  }

  filterRooms() {
    const query = this.searchInputTarget.value.trim().toLowerCase()
    
    if (query.length === 0) {
      this.renderRooms(this.rooms)
    } else {
      const filtered = this.rooms.filter(room => 
        room.name.toLowerCase().includes(query)
      )
      this.renderRooms(filtered)
    }
  }

  renderRooms(rooms) {
    if (rooms.length === 0) {
      this.roomListTarget.innerHTML = `
        <div class="px-4 py-3 text-sm text-neutral-500 italic">
          No rooms available to join
        </div>
      `
      return
    }

    this.roomListTarget.innerHTML = rooms.map(room => `
      <div class="flex items-center justify-between px-4 py-3 hover:bg-neutral-800 transition-colors">
        <div class="flex items-center gap-2">
          <span class="text-neutral-500">#</span>
          <span class="text-sm text-neutral-200">${this.escapeHtml(room.name)}</span>
          <span class="text-xs text-neutral-600">${room.member_count} ${room.member_count === 1 ? 'member' : 'members'}</span>
        </div>
        <button
          type="button"
          class="px-3 py-1 text-xs uppercase tracking-wide text-[#00ff88] border border-[#00ff88] hover:bg-[#00ff88] hover:text-black transition-colors"
          data-action="click->room-browse#joinRoom"
          data-room-id="${room.id}"
        >
          Join
        </button>
      </div>
    `).join("")
  }

  async joinRoom(event) {
    const roomId = event.currentTarget.dataset.roomId
    const button = event.currentTarget
    
    button.disabled = true
    button.textContent = "Joining..."

    try {
      const response = await fetch(`/rooms/${roomId}/memberships`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content
        }
      })

      if (response.ok || response.redirected) {
        // Redirect to the room
        window.location.href = `/rooms/${roomId}`
      } else {
        button.disabled = false
        button.textContent = "Join"
        console.error("Failed to join room")
      }
    } catch (error) {
      button.disabled = false
      button.textContent = "Join"
      console.error("Failed to join room:", error)
    }
  }

  escapeHtml(text) {
    const div = document.createElement("div")
    div.textContent = text
    return div.innerHTML
  }
}
