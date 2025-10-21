import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="orders-table"
export default class extends Controller {
  connect() {
    console.log("Orders table controller connected")
  }

  // Order status update
  updateOrderStatus(event) {
    const orderId = event.currentTarget.dataset.orderId
    const newStatus = event.currentTarget.value

    // Show loading state
    const originalValue = event.currentTarget.value
    const originalHTML = event.currentTarget.innerHTML

    event.currentTarget.disabled = true
    event.currentTarget.innerHTML = '<option>Updating...</option>'

    // Trigger the Stimulus controller on the parent to handle the update
    const parentController = this.element.closest('[data-controller="orders-management"]')
    if (parentController && parentController.stimulusController) {
      parentController.stimulusController.updateOrderStatus(Object.assign({}, event, {
        currentTarget: event.currentTarget,
        target: event.currentTarget
      }))
    }
  }
}
