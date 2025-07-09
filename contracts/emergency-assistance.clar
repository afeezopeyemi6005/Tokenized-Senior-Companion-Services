;; Emergency Assistance Contract
;; Ensures rapid help during health crises

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u500))
(define-constant ERR_NOT_FOUND (err u501))
(define-constant ERR_ALREADY_EXISTS (err u502))
(define-constant ERR_INVALID_INPUT (err u503))
(define-constant ERR_EMERGENCY_ACTIVE (err u504))

;; Data Variables
(define-data-var next-emergency-id uint u1)
(define-data-var next-contact-id uint u1)

;; Data Maps
(define-map emergency-contacts
  uint
  {
    senior-id: uint,
    contact-name: (string-ascii 50),
    relationship: (string-ascii 30),
    phone: (string-ascii 20),
    email: (string-ascii 100),
    address: (string-ascii 200),
    priority: uint,
    active: bool,
    added-by: principal,
    added-at: uint
  }
)

(define-map emergency-incidents
  uint
  {
    senior-id: uint,
    incident-type: (string-ascii 50),
    severity: uint,
    location: (string-ascii 200),
    description: (string-ascii 1000),
    reported-by: principal,
    reported-at: uint,
    status: (string-ascii 20),
    response-time: (optional uint),
    resolved-at: (optional uint),
    responders: (list 5 principal),
    notes: (string-ascii 1000)
  }
)

(define-map emergency-responders
  principal
  {
    name: (string-ascii 50),
    specialization: (string-ascii 50),
    phone: (string-ascii 20),
    location: (string-ascii 100),
    available: bool,
    response-count: uint,
    average-response-time: uint,
    rating: uint
  }
)

(define-map senior-emergency-contacts
  uint
  (list 10 uint)
)

(define-map senior-emergency-history
  uint
  (list 50 uint)
)

(define-map responder-incidents
  principal
  (list 100 uint)
)

;; Public Functions

;; Add emergency contact for a senior
(define-public (add-emergency-contact
  (senior-id uint)
  (contact-name (string-ascii 50))
  (relationship (string-ascii 30))
  (phone (string-ascii 20))
  (email (string-ascii 100))
  (address (string-ascii 200))
  (priority uint)
)
  (let ((contact-id (var-get next-contact-id)))
    (asserts! (> (len contact-name) u0) ERR_INVALID_INPUT)
    (asserts! (> (len phone) u0) ERR_INVALID_INPUT)
    (asserts! (and (>= priority u1) (<= priority u5)) ERR_INVALID_INPUT)

    (map-set emergency-contacts contact-id {
      senior-id: senior-id,
      contact-name: contact-name,
      relationship: relationship,
      phone: phone,
      email: email,
      address: address,
      priority: priority,
      active: true,
      added-by: tx-sender,
      added-at: block-height
    })

    ;; Update senior's emergency contacts list
    (update-senior-contacts senior-id contact-id)

    (var-set next-contact-id (+ contact-id u1))
    (ok contact-id)
  )
)

;; Register as emergency responder
(define-public (register-responder
  (name (string-ascii 50))
  (specialization (string-ascii 50))
  (phone (string-ascii 20))
  (location (string-ascii 100))
)
  (begin
    (asserts! (> (len name) u0) ERR_INVALID_INPUT)
    (asserts! (> (len phone) u0) ERR_INVALID_INPUT)
    (asserts! (is-none (map-get? emergency-responders tx-sender)) ERR_ALREADY_EXISTS)

    (map-set emergency-responders tx-sender {
      name: name,
      specialization: specialization,
      phone: phone,
      location: location,
      available: true,
      response-count: u0,
      average-response-time: u0,
      rating: u5
    })

    (ok true)
  )
)

;; Report an emergency incident
(define-public (report-emergency
  (senior-id uint)
  (incident-type (string-ascii 50))
  (severity uint)
  (location (string-ascii 200))
  (description (string-ascii 1000))
)
  (let ((emergency-id (var-get next-emergency-id)))
    (asserts! (> (len incident-type) u0) ERR_INVALID_INPUT)
    (asserts! (and (>= severity u1) (<= severity u5)) ERR_INVALID_INPUT)
    (asserts! (> (len location) u0) ERR_INVALID_INPUT)

    (map-set emergency-incidents emergency-id {
      senior-id: senior-id,
      incident-type: incident-type,
      severity: severity,
      location: location,
      description: description,
      reported-by: tx-sender,
      reported-at: block-height,
      status: "active",
      response-time: none,
      resolved-at: none,
      responders: (list),
      notes: ""
    })

    ;; Update senior's emergency history
    (update-senior-emergency-history senior-id emergency-id)

    ;; Auto-notify emergency contacts for high severity incidents
    (if (>= severity u4)
        (notify-emergency-contacts senior-id emergency-id)
        true
    )

    (var-set next-emergency-id (+ emergency-id u1))
    (ok emergency-id)
  )
)

;; Respond to emergency as a responder
(define-public (respond-to-emergency (emergency-id uint))
  (let (
    (incident (unwrap! (map-get? emergency-incidents emergency-id) ERR_NOT_FOUND))
    (responder (unwrap! (map-get? emergency-responders tx-sender) ERR_UNAUTHORIZED))
  )
    (asserts! (is-eq (get status incident) "active") ERR_INVALID_INPUT)
    (asserts! (get available responder) ERR_UNAUTHORIZED)
    (asserts! (is-none (index-of (get responders incident) tx-sender)) ERR_ALREADY_EXISTS)

    ;; Add responder to incident
    (let ((updated-responders (unwrap-panic (as-max-len? (append (get responders incident) tx-sender) u5))))
      (map-set emergency-incidents emergency-id (merge incident {
        responders: updated-responders,
        status: "responding",
        response-time: (if (is-none (get response-time incident))
                          (some (- block-height (get reported-at incident)))
                          (get response-time incident))
      }))
    )

    ;; Update responder's incident list
    (update-responder-incidents tx-sender emergency-id)

    ;; Update responder availability
    (map-set emergency-responders tx-sender (merge responder { available: false }))

    (ok true)
  )
)

;; Resolve emergency incident
(define-public (resolve-emergency (emergency-id uint) (resolution-notes (string-ascii 1000)))
  (let ((incident (unwrap! (map-get? emergency-incidents emergency-id) ERR_NOT_FOUND)))
    (asserts! (or (is-eq tx-sender (get reported-by incident))
                  (is-some (index-of (get responders incident) tx-sender))) ERR_UNAUTHORIZED)
    (asserts! (not (is-eq (get status incident) "resolved")) ERR_INVALID_INPUT)

    (map-set emergency-incidents emergency-id (merge incident {
      status: "resolved",
      resolved-at: (some block-height),
      notes: resolution-notes
    }))

    ;; Update responder availability
    (update-responders-availability (get responders incident))

    ;; Update responder statistics
    (update-responder-stats (get responders incident) emergency-id)

    (ok true)
  )
)

;; Update emergency contact
(define-public (update-emergency-contact
  (contact-id uint)
  (phone (string-ascii 20))
  (email (string-ascii 100))
  (address (string-ascii 200))
  (priority uint)
)
  (let ((contact (unwrap! (map-get? emergency-contacts contact-id) ERR_NOT_FOUND)))
    (asserts! (is-eq tx-sender (get added-by contact)) ERR_UNAUTHORIZED)
    (asserts! (and (>= priority u1) (<= priority u5)) ERR_INVALID_INPUT)

    (map-set emergency-contacts contact-id (merge contact {
      phone: phone,
      email: email,
      address: address,
      priority: priority
    }))

    (ok true)
  )
)

;; Update responder availability
(define-public (update-responder-availability (available bool))
  (let ((responder (unwrap! (map-get? emergency-responders tx-sender) ERR_NOT_FOUND)))
    (map-set emergency-responders tx-sender (merge responder { available: available }))
    (ok true)
  )
)

;; Read-only Functions

(define-read-only (get-emergency-contact (contact-id uint))
  (map-get? emergency-contacts contact-id)
)

(define-read-only (get-emergency-incident (emergency-id uint))
  (map-get? emergency-incidents emergency-id)
)

(define-read-only (get-emergency-responder (responder principal))
  (map-get? emergency-responders responder)
)

(define-read-only (get-senior-emergency-contacts (senior-id uint))
  (default-to (list) (map-get? senior-emergency-contacts senior-id))
)

(define-read-only (get-senior-emergency-history (senior-id uint))
  (default-to (list) (map-get? senior-emergency-history senior-id))
)

(define-read-only (get-active-emergencies)
  ;; This would return a list of active emergencies - simplified for this example
  (list)
)

(define-read-only (get-available-responders)
  ;; This would return a list of available responders - simplified for this example
  (list)
)

;; Private Functions

(define-private (update-senior-contacts (senior-id uint) (contact-id uint))
  (let ((current-contacts (default-to (list) (map-get? senior-emergency-contacts senior-id))))
    (map-set senior-emergency-contacts senior-id (unwrap-panic (as-max-len? (append current-contacts contact-id) u10)))
  )
)

(define-private (update-senior-emergency-history (senior-id uint) (emergency-id uint))
  (let ((current-history (default-to (list) (map-get? senior-emergency-history senior-id))))
    (map-set senior-emergency-history senior-id (unwrap-panic (as-max-len? (append current-history emergency-id) u50)))
  )
)

(define-private (update-responder-incidents (responder principal) (emergency-id uint))
  (let ((current-incidents (default-to (list) (map-get? responder-incidents responder))))
    (map-set responder-incidents responder (unwrap-panic (as-max-len? (append current-incidents emergency-id) u100)))
  )
)

(define-private (notify-emergency-contacts (senior-id uint) (emergency-id uint))
  ;; This would trigger notifications to emergency contacts
  ;; Implementation would depend on off-chain notification system
  true
)

(define-private (update-responders-availability (responders (list 5 principal)))
  (fold update-single-responder-availability responders true)
)

(define-private (update-single-responder-availability (responder principal) (acc bool))
  (match (map-get? emergency-responders responder)
    resp (begin
           (map-set emergency-responders responder (merge resp { available: true }))
           true)
    false
  )
)

(define-private (update-responder-stats (responders (list 5 principal)) (emergency-id uint))
  (fold update-single-responder-stats responders emergency-id)
)

(define-private (update-single-responder-stats (responder principal) (emergency-id uint))
  (match (map-get? emergency-responders responder)
    resp (begin
           (map-set emergency-responders responder (merge resp {
             response-count: (+ (get response-count resp) u1)
           }))
           emergency-id)
    emergency-id
  )
)
