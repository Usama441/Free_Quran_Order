import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="orders-management"
export default class extends Controller {
  static targets = ["searchInput", "startDate", "endDate", "status", "pendingCount", "processingCount", "shippedCount", "deliveredCount", "perPageSelect"]

  connect() {
    console.log("Orders management controller connected")
  }

  // Search functionality
  search(event) {
    this.updateOrders()
  }

  // Filter functionality
  filter(event) {
    this.updateOrders()
  }

  // Update orders via AJAX
  async updateOrders() {
    const searchValue = this.searchInputTarget.value
    const statusValue = this.statusTarget.value
    const startDateValue = this.startDateTarget ? this.startDateTarget.querySelector('input').value : null
    const endDateValue = this.endDateTarget ? this.endDateTarget.querySelector('input').value : null

    const params = new URLSearchParams()
    if (searchValue) params.append('search', searchValue)
    if (statusValue) params.append('status', statusValue)
    if (startDateValue) params.append('start_date', startDateValue)
    if (endDateValue) params.append('end_date', endDateValue)

    try {
      const response = await fetch(`/admin/orders?${params}&format=json`, {
        method: 'GET',
        headers: {
          'Accept': 'application/json',
          'X-CSRF-Token': this.getCsrfToken()
        }
      })

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`)
      }

      const data = await response.json()

      // Update orders table
      this.element.querySelector('#orders-table-container').innerHTML = data.html

      // Update counts
      this.pendingCountTarget.textContent = data.pending_count
      this.processingCountTarget.textContent = data.processing_count
      this.shippedCountTarget.textContent = data.shipped_count
      this.deliveredCountTarget.textContent = data.delivered_count

      this.showFlashMessage('success', 'Orders filtered successfully!')
    } catch (error) {
      console.error('Error:', error)
      this.showFlashMessage('error', 'Failed to filter orders. Please try again.')
    }
  }

  // Clear all filters
  clearFilters() {
    this.searchTarget.value = ''
    this.statusTarget.value = ''
    window.location.href = '/admin/orders'
  }

  // Handle per-page change
  updatePerPage(event) {
    const perPage = event.target.value;
    const url = new URL(window.location);
    url.searchParams.set('per_page', perPage);
    url.searchParams.set('page', '1'); // Reset to first page when changing per_page
    window.location.href = url.toString();
  }

  // Order status update
  async updateOrderStatus(event) {
    const orderId = event.currentTarget.dataset.orderId
    const newStatus = event.currentTarget.value

    // Show loading state
    const originalValue = event.currentTarget.value
    event.currentTarget.disabled = true
    event.currentTarget.innerHTML = '<option>Updating...</option>'

    try {
      const response = await fetch(`/admin/orders/${orderId}/status`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-CSRF-Token': this.getCsrfToken()
        },
        body: JSON.stringify({ status: newStatus })
      })

      if (!response.ok) {
        const errorData = await response.json()
        throw new Error(errorData.error || `HTTP error! status: ${response.status}`)
      }

      const data = await response.json()

      if (data.success) {
        // Update badge immediately
        this.updateStatusBadge(orderId, newStatus)

        // Reset dropdown
        event.currentTarget.disabled = false
        let html = `<option value="${newStatus}">${newStatus.titleize()} (Current)</option>`
        html += '<option value="pending">Pending</option>'
        html += '<option value="processing">Processing</option>'
        html += '<option value="shipped">Shipped</option>'
        html += '<option value="delivered">Delivered</option>'
        html += '<option value="cancelled">Cancelled</option>'
        event.currentTarget.innerHTML = html

        // Update counts
        await this.updateCounts()

        this.showFlashMessage('success', `Status updated to ${newStatus.titleize()} successfully!`)
      } else {
        throw new Error(data.error || 'Failed to update status')
      }
    } catch (error) {
      // Reset dropdown on error
      event.currentTarget.disabled = false
      let html = `<option value="${originalValue}">${originalValue.titleize()} (Current)</option>`
      html += '<option value="pending">Pending</option>'
      html += '<option value="processing">Processing</option>'
      html += '<option value="shipped">Shipped</option>'
      html += '<option value="delivered">Delivered</option>'
      html += '<option value="cancelled">Cancelled</option>'
      event.currentTarget.innerHTML = html

      console.error('Error:', error)
      this.showFlashMessage('error', error.message)
    }
  }

  // Update status badge on the page
  updateStatusBadge(orderId, newStatus) {
    const badge = this.element.querySelector(`#order-${orderId}-status-badge`) ||
                  this.element.querySelector(`[id$="order-${orderId}-status-badge"]`)

    if (badge) {
      // Remove existing classes
      badge.className = badge.className.replace(/bg-(red|yellow|blue|green)-100/g, '').replace(/text-(red|yellow|blue|green)-800/g, '')

      // Add new classes based on status
      const classes = {
        'pending': 'bg-red-100 text-red-800',
        'processing': 'bg-yellow-100 text-yellow-800',
        'shipped': 'bg-blue-100 text-blue-800',
        'delivered': 'bg-green-100 text-green-800',
        'cancelled': 'bg-red-100 text-red-800'
      }

      badge.classList.add(...classes[newStatus].split(' '))
      badge.textContent = newStatus.titleize()
    }
  }

  // Update count badges
  async updateCounts() {
    try {
      const response = await fetch('/admin/orders', {
        method: 'GET',
        headers: {
          'Accept': 'application/json',
          'X-CSRF-Token': this.getCsrfToken()
        }
      })

      if (response.ok) {
        const data = await response.json()
        this.pendingCountTarget.textContent = data.pending_count || 0
        this.processingCountTarget.textContent = data.processing_count || 0
        this.shippedCountTarget.textContent = data.shipped_count || 0
        this.deliveredCountTarget.textContent = data.delivered_count || 0
      }
    } catch (error) {
      console.error('Error updating counts:', error)
    }
  }

  // Helper methods
  getCsrfToken() {
    const tokenElement = document.querySelector('[name="authenticity_token"]')
    if (tokenElement) {
      return tokenElement.value
    }
    return document.querySelector('meta[name="csrf-token"]')?.getAttribute('content') || ''
  }

  showFlashMessage(type, message) {
    const existingAlert = document.querySelector('.flash-message')
    if (existingAlert) {
      existingAlert.remove()
    }

    const alertDiv = document.createElement('div')
    alertDiv.className = `flash-message fixed top-4 right-4 z-50 px-6 py-4 rounded-lg shadow-lg ${type === 'success' ? 'bg-green-500' : 'bg-red-500'} text-white max-w-sm`
    alertDiv.innerHTML = `
      <div class="flex items-center">
        <i class="fas ${type === 'success' ? 'fa-check-circle' : 'fa-exclamation-circle'} mr-2"></i>
        <span>${message}</span>
      </div>
    `

    document.body.appendChild(alertDiv)

    setTimeout(() => {
      if (alertDiv.parentNode) {
        alertDiv.remove()
      }
    }, 5000)
  }
}
