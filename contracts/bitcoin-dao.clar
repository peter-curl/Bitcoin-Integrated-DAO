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