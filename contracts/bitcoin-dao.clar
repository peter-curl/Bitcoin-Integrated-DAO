;; Bitcoin DAO Smart Contract

;; This smart contract implements a decentralized autonomous organization (DAO) on the Bitcoin blockchain,
;; allowing users to stake BTC (simulated with STX for testing), create proposals, vote on them,
;; and execute proposals if they meet the required conditions.

;; Constants
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-PROPOSAL-NOT-FOUND (err u101))
(define-constant ERR-INVALID-AMOUNT (err u102))
(define-constant ERR-ALREADY-VOTED (err u103))
(define-constant ERR-PROPOSAL-EXPIRED (err u104))
(define-constant ERR-INSUFFICIENT-STAKE (err u105))
(define-constant ERR-PROPOSAL-NOT-ACTIVE (err u106))
(define-constant ERR-INVALID-STATE (err u107))

;; Data Variables
(define-data-var min-proposal-stake uint u100000) ;; Minimum BTC stake required for proposal (in sats)
(define-data-var proposal-duration uint u144) ;; Duration in blocks (approximately 1 day)
(define-data-var total-staked uint u0)
(define-data-var proposal-count uint u0)

;; Data Maps
(define-map proposals
    uint ;; proposal-id
    {
        creator: principal,
        title: (string-ascii 50),
        description: (string-ascii 500),
        start-block: uint,
        end-block: uint,
        status: (string-ascii 10),
        yes-votes: uint,
        no-votes: uint,
        executed: bool,
        min-votes-required: uint
    }
)

(define-map user-stakes
    principal ;; user address
    uint ;; amount staked in sats
)

(define-map votes
    {proposal-id: uint, voter: principal}
    {vote: bool, weight: uint}
)

;; Private Functions
(define-private (is-proposal-active (proposal-id uint))
    (let (
        (proposal (unwrap! (map-get? proposals proposal-id) false))
        (current-block block-height)
    )
    (and
        (>= current-block (get start-block proposal))
        (<= current-block (get end-block proposal))
        (is-eq (get status proposal) "active")
    ))
)

(define-private (can-execute-proposal (proposal-id uint))
    (let (
        (proposal (unwrap! (map-get? proposals proposal-id) false))
        (total-votes (+ (get yes-votes proposal) (get no-votes proposal)))
    )
    (and
        (>= total-votes (get min-votes-required proposal))
        (> (get yes-votes proposal) (get no-votes proposal))
        (not (get executed proposal))
        (>= block-height (get end-block proposal))
    ))
)

;; Public Functions

;; Stake BTC (simulated with STX for testing)
(define-public (stake (amount uint))
    (let (
        (current-stake (default-to u0 (map-get? user-stakes tx-sender)))
        (new-stake (+ current-stake amount))
    )
    (begin
        (asserts! (> amount u0) ERR-INVALID-AMOUNT)
        (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
        (map-set user-stakes tx-sender new-stake)
        (var-set total-staked (+ (var-get total-staked) amount))
        (ok new-stake)
    ))
)

;; Create a new proposal
(define-public (create-proposal (title (string-ascii 50)) (description (string-ascii 500)) (duration uint))
    (let (
        (user-stake (default-to u0 (map-get? user-stakes tx-sender)))
        (proposal-id (+ (var-get proposal-count) u1))
        (start-block block-height)
        (end-block (+ block-height duration))
    )
    (begin
        (asserts! (>= user-stake (var-get min-proposal-stake)) ERR-INSUFFICIENT-STAKE)
        (asserts! (> duration u0) ERR-INVALID-AMOUNT)
        
        (map-set proposals proposal-id {
            creator: tx-sender,
            title: title,
            description: description,
            start-block: start-block,
            end-block: end-block,
            status: "active",
            yes-votes: u0,
            no-votes: u0,
            executed: false,
            min-votes-required: (/ (var-get total-staked) u10) ;; 10% quorum
        })
        
        (var-set proposal-count proposal-id)
        (ok proposal-id)
    ))
)

;; Vote on a proposal
(define-public (vote (proposal-id uint) (vote-for bool))
    (let (
        (user-stake (default-to u0 (map-get? user-stakes tx-sender)))
        (proposal (unwrap! (map-get? proposals proposal-id) ERR-PROPOSAL-NOT-FOUND))
        (vote-key {proposal-id: proposal-id, voter: tx-sender})
    )
    (begin
        (asserts! (is-proposal-active proposal-id) ERR-PROPOSAL-NOT-ACTIVE)
        (asserts! (> user-stake u0) ERR-INSUFFICIENT-STAKE)
        (asserts! (is-none (map-get? votes vote-key)) ERR-ALREADY-VOTED)
        
        (map-set votes vote-key {vote: vote-for, weight: user-stake})
        
        (map-set proposals proposal-id 
            (merge proposal 
                {
                    yes-votes: (if vote-for 
                        (+ (get yes-votes proposal) user-stake)
                        (get yes-votes proposal)),
                    no-votes: (if vote-for 
                        (get no-votes proposal)
                        (+ (get no-votes proposal) user-stake))
                }
            )
        )
        (ok true)
    ))
)

;; Execute a proposal
(define-public (execute-proposal (proposal-id uint))
    (let (
        (proposal (unwrap! (map-get? proposals proposal-id) ERR-PROPOSAL-NOT-FOUND))
    )
    (begin
        (asserts! (can-execute-proposal proposal-id) ERR-INVALID-STATE)
        
        ;; Update proposal status
        (map-set proposals proposal-id 
            (merge proposal {
                status: "executed",
                executed: true
            })
        )
        (ok true)
    ))
)