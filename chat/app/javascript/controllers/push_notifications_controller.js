import { Controller } from "@hotwired/stimulus"

// Handles push notification subscription and permission management
// Add to any element: data-controller="push-notifications"
// Optionally add button: data-push-notifications-target="button"
export default class extends Controller {
  static targets = ["button", "status"]

  connect() {
    this.updateUI()
    this.registerServiceWorker()
  }

  async registerServiceWorker() {
    if (!("serviceWorker" in navigator)) {
      this.setStatus("not-supported")
      return
    }

    // Check for iOS Safari that requires PWA installation
    if (this.isIOSSafari && !this.isStandalone) {
      this.setStatus("ios-needs-install")
      return
    }

    try {
      const registration = await navigator.serviceWorker.register("/service-worker")
      this.swRegistration = registration
      
      // Check if already subscribed
      const subscription = await registration.pushManager.getSubscription()
      if (subscription) {
        this.setStatus("subscribed")
      } else {
        this.setStatus("unsubscribed")
      }
    } catch (error) {
      console.error("Service worker registration failed:", error)
      this.setStatus("error")
    }
  }

  // Detect iOS Safari (not Chrome/Firefox on iOS, which also can't do push)
  get isIOSSafari() {
    const ua = navigator.userAgent
    const isIOS = /iPad|iPhone|iPod/.test(ua) || (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1)
    return isIOS
  }

  // Check if running as installed PWA (standalone mode)
  get isStandalone() {
    return window.matchMedia('(display-mode: standalone)').matches || 
           window.navigator.standalone === true
  }

  async toggle() {
    const subscription = await this.swRegistration?.pushManager.getSubscription()
    
    if (subscription) {
      await this.unsubscribe(subscription)
    } else {
      await this.subscribe()
    }
  }

  async subscribe() {
    if (!this.swRegistration) return

    // Request permission
    const permission = await Notification.requestPermission()
    if (permission !== "granted") {
      this.setStatus("denied")
      return
    }

    try {
      // Get VAPID public key from server
      const response = await fetch("/push_subscriptions/vapid_public_key")
      const { vapid_public_key } = await response.json()

      if (!vapid_public_key) {
        this.setStatus("not-configured")
        return
      }

      // Subscribe to push
      const subscription = await this.swRegistration.pushManager.subscribe({
        userVisibleOnly: true,
        applicationServerKey: this.urlBase64ToUint8Array(vapid_public_key)
      })

      // Send subscription to server
      await this.saveSubscription(subscription)
      this.setStatus("subscribed")
    } catch (error) {
      console.error("Push subscription failed:", error)
      
      // Provide more specific error messages
      if (this.isIOSSafari) {
        // iOS 16.4+ required for push, and must be installed as PWA
        this.setStatus("ios-needs-install")
      } else {
        this.setStatus("error")
      }
    }
  }

  async unsubscribe(subscription) {
    try {
      // Unsubscribe from push
      await subscription.unsubscribe()

      // Remove from server
      await fetch("/push_subscriptions", {
        method: "DELETE",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": this.csrfToken
        },
        body: JSON.stringify({ endpoint: subscription.endpoint })
      })

      this.setStatus("unsubscribed")
    } catch (error) {
      console.error("Unsubscribe failed:", error)
      this.setStatus("error")
    }
  }

  async saveSubscription(subscription) {
    const keys = subscription.toJSON().keys

    await fetch("/push_subscriptions", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": this.csrfToken
      },
      body: JSON.stringify({
        push_subscription: {
          endpoint: subscription.endpoint,
          p256dh: keys.p256dh,
          auth: keys.auth
        }
      })
    })
  }

  setStatus(status) {
    this.status = status
    this.updateUI()
  }

  updateUI() {
    if (this.hasButtonTarget) {
      const button = this.buttonTarget

      switch (this.status) {
        case "subscribed":
          button.textContent = "Disable notifications"
          button.disabled = false
          break
        case "unsubscribed":
          button.textContent = "Enable notifications"
          button.disabled = false
          break
        case "denied":
          button.textContent = "Notifications blocked"
          button.disabled = true
          break
        case "not-supported":
          button.textContent = "Not supported"
          button.disabled = true
          break
        case "not-configured":
          button.textContent = "Not available"
          button.disabled = true
          break
        case "ios-needs-install":
          button.textContent = "Add to Home Screen first"
          button.disabled = true
          break
        case "error":
          button.textContent = "Error"
          button.disabled = true
          break
        default:
          button.textContent = "Loading..."
          button.disabled = true
      }
    }

    if (this.hasStatusTarget) {
      this.statusTarget.dataset.status = this.status
    }
  }

  // Convert VAPID key from base64 to Uint8Array
  urlBase64ToUint8Array(base64String) {
    const padding = "=".repeat((4 - base64String.length % 4) % 4)
    const base64 = (base64String + padding)
      .replace(/-/g, "+")
      .replace(/_/g, "/")

    const rawData = window.atob(base64)
    const outputArray = new Uint8Array(rawData.length)

    for (let i = 0; i < rawData.length; ++i) {
      outputArray[i] = rawData.charCodeAt(i)
    }
    return outputArray
  }

  get csrfToken() {
    return document.querySelector('meta[name="csrf-token"]')?.content
  }
}
