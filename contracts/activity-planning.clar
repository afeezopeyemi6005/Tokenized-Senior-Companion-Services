;; Activity Planning Contract
;; Coordinates engaging recreational experiences

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u200))
(define-constant ERR_NOT_FOUND (err u201))
(define-constant ERR_ALREADY_EXISTS (err u202))
(define-constant ERR_INVALID_INPUT (err u203))
(define-constant ERR_ACTIVITY_FULL (err u204))

;; Data Variables
(define-data-var next-activity-id uint u1)
(define-data-var next-booking-id uint u1)

;; Data Maps
(define-map activities
  uint
  {
    creator: principal,
    title: (string-ascii 100),
    description: (string-ascii 500),
    category: (string-ascii 30),
    location: (string-ascii 100),
    date: uint,
    duration: uint,
    max-participants: uint,
    current-participants: uint,
    cost-per-person: uint,
    status: (string-ascii 20),
    created-at: uint
  }
)

(define-map bookings
  uint
  {
    activity-id: uint,
    participant: principal,
    companion: (optional principal),
    booking-date: uint,
    status: (string-ascii 20),
    payment-amount: uint,
    completed: bool,
    rating: (optional uint)
  }
)

(define-map activity-participants
  { activity-id: uint, participant: principal }
  bool
)

(define-map user-bookings
  principal
  (list 50 uint)
)

;; Public Functions

;; Create a new activity
(define-public (create-activity
  (title (string-ascii 100))
  (description (string-ascii 500))
  (category (string-ascii 30))
  (location (string-ascii 100))
  (date uint)
  (duration uint)
  (max-participants uint)
  (cost-per-person uint)
)
  (let ((activity-id (var-get next-activity-id)))
    (asserts! (> (len title) u0) ERR_INVALID_INPUT)
    (asserts! (> date block-height) ERR_INVALID_INPUT)
    (asserts! (> duration u0) ERR_INVALID_INPUT)
    (asserts! (> max-participants u0) ERR_INVALID_INPUT)

    (map-set activities activity-id {
      creator: tx-sender,
      title: title,
      description: description,
      category: category,
      location: location,
      date: date,
      duration: duration,
      max-participants: max-participants,
      current-participants: u0,
      cost-per-person: cost-per-person,
      status: "open",
      created-at: block-height
    })

    (var-set next-activity-id (+ activity-id u1))
    (ok activity-id)
  )
)

;; Book an activity
(define-public (book-activity (activity-id uint) (companion (optional principal)))
  (let (
    (activity (unwrap! (map-get? activities activity-id) ERR_NOT_FOUND))
    (booking-id (var-get next-booking-id))
  )
    (asserts! (is-eq (get status activity) "open") ERR_INVALID_INPUT)
    (asserts! (< (get current-participants activity) (get max-participants activity)) ERR_ACTIVITY_FULL)
    (asserts! (> (get date activity) block-height) ERR_INVALID_INPUT)
    (asserts! (is-none (map-get? activity-participants { activity-id: activity-id, participant: tx-sender })) ERR_ALREADY_EXISTS)

    ;; Process payment
    (try! (stx-transfer? (get cost-per-person activity) tx-sender (get creator activity)))

    ;; Create booking
    (map-set bookings booking-id {
      activity-id: activity-id,
      participant: tx-sender,
      companion: companion,
      booking-date: block-height,
      status: "confirmed",
      payment-amount: (get cost-per-person activity),
      completed: false,
      rating: none
    })

    ;; Update activity participants
    (map-set activity-participants { activity-id: activity-id, participant: tx-sender } true)

    ;; Update activity participant count
    (map-set activities activity-id (merge activity {
      current-participants: (+ (get current-participants activity) u1)
    }))

    ;; Update user bookings
    (update-user-bookings tx-sender booking-id)

    (var-set next-booking-id (+ booking-id u1))
    (ok booking-id)
  )
)

;; Complete an activity and rate it
(define-public (complete-activity (booking-id uint) (rating uint))
  (let ((booking (unwrap! (map-get? bookings booking-id) ERR_NOT_FOUND)))
    (asserts! (is-eq tx-sender (get participant booking)) ERR_UNAUTHORIZED)
    (asserts! (not (get completed booking)) ERR_INVALID_INPUT)
    (asserts! (and (>= rating u1) (<= rating u10)) ERR_INVALID_INPUT)

    (map-set bookings booking-id (merge booking {
      completed: true,
      rating: (some rating),
      status: "completed"
    }))

    (ok true)
  )
)

;; Cancel a booking
(define-public (cancel-booking (booking-id uint))
  (let (
    (booking (unwrap! (map-get? bookings booking-id) ERR_NOT_FOUND))
    (activity (unwrap! (map-get? activities (get activity-id booking)) ERR_NOT_FOUND))
  )
    (asserts! (is-eq tx-sender (get participant booking)) ERR_UNAUTHORIZED)
    (asserts! (is-eq (get status booking) "confirmed") ERR_INVALID_INPUT)
    (asserts! (> (get date activity) (+ block-height u144)) ERR_INVALID_INPUT) ;; 24 hours notice

    ;; Refund payment
    (try! (stx-transfer? (get payment-amount booking) (get creator activity) tx-sender))

    ;; Update booking status
    (map-set bookings booking-id (merge booking { status: "cancelled" }))

    ;; Remove from activity participants
    (map-delete activity-participants { activity-id: (get activity-id booking), participant: tx-sender })

    ;; Update activity participant count
    (map-set activities (get activity-id booking) (merge activity {
      current-participants: (- (get current-participants activity) u1)
    }))

    (ok true)
  )
)

;; Update activity status
(define-public (update-activity-status (activity-id uint) (new-status (string-ascii 20)))
  (let ((activity (unwrap! (map-get? activities activity-id) ERR_NOT_FOUND)))
    (asserts! (is-eq tx-sender (get creator activity)) ERR_UNAUTHORIZED)

    (map-set activities activity-id (merge activity { status: new-status }))
    (ok true)
  )
)

;; Read-only Functions

(define-read-only (get-activity (activity-id uint))
  (map-get? activities activity-id)
)

(define-read-only (get-booking (booking-id uint))
  (map-get? bookings booking-id)
)

(define-read-only (is-participant (activity-id uint) (participant principal))
  (default-to false (map-get? activity-participants { activity-id: activity-id, participant: participant }))
)

(define-read-only (get-user-bookings (user principal))
  (default-to (list) (map-get? user-bookings user))
)

(define-read-only (get-activity-availability (activity-id uint))
  (match (map-get? activities activity-id)
    activity (- (get max-participants activity) (get current-participants activity))
    u0
  )
)

;; Private Functions

(define-private (update-user-bookings (user principal) (booking-id uint))
  (let ((current-bookings (default-to (list) (map-get? user-bookings user))))
    (map-set user-bookings user (unwrap-panic (as-max-len? (append current-bookings booking-id) u50)))
  )
)
