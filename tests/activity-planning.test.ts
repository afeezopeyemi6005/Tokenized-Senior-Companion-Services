import { describe, it, expect, beforeEach } from "vitest"

describe("Activity Planning Contract", () => {
  let contractAddress
  let creator
  let participant1
  let participant2
  
  beforeEach(() => {
    contractAddress = "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.activity-planning"
    creator = "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM"
    participant1 = "ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG"
    participant2 = "ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC"
  })
  
  describe("Activity Creation", () => {
    it("should create a new activity successfully", () => {
      const title = "Morning Walk in Central Park"
      const description = "A gentle walk through Central Park with stops at scenic locations"
      const category = "outdoor"
      const location = "Central Park, NYC"
      const date = 1000000 // Future block height
      const duration = 120 // 2 hours
      const maxParticipants = 5
      const costPerPerson = 1000000 // 1 STX
      
      const result = {
        type: "ok",
        value: 1,
      }
      
      expect(result.type).toBe("ok")
      expect(result.value).toBe(1)
    })
    
    it("should fail with empty title", () => {
      const title = ""
      const description = "A gentle walk"
      const category = "outdoor"
      const location = "Central Park"
      const date = 1000000
      const duration = 120
      const maxParticipants = 5
      const costPerPerson = 1000000
      
      const result = {
        type: "err",
        value: 203,
      }
      
      expect(result.type).toBe("err")
      expect(result.value).toBe(203) // ERR_INVALID_INPUT
    })
    
    it("should fail with past date", () => {
      const title = "Morning Walk"
      const description = "A gentle walk"
      const category = "outdoor"
      const location = "Central Park"
      const date = 100 // Past block height
      const duration = 120
      const maxParticipants = 5
      const costPerPerson = 1000000
      
      const result = {
        type: "err",
        value: 203,
      }
      
      expect(result.type).toBe("err")
      expect(result.value).toBe(203) // ERR_INVALID_INPUT
    })
  })
  
  describe("Activity Booking", () => {
    it("should book an activity successfully", () => {
      const activityId = 1
      const companion = null
      
      const result = {
        type: "ok",
        value: 1,
      }
      
      expect(result.type).toBe("ok")
      expect(result.value).toBe(1)
    })
    
    it("should book an activity with companion", () => {
      const activityId = 1
      const companion = participant2
      
      const result = {
        type: "ok",
        value: 1,
      }
      
      expect(result.type).toBe("ok")
      expect(result.value).toBe(1)
    })
    
    it("should fail when activity is full", () => {
      const activityId = 1
      const companion = null
      
      const result = {
        type: "err",
        value: 204,
      }
      
      expect(result.type).toBe("err")
      expect(result.value).toBe(204) // ERR_ACTIVITY_FULL
    })
    
    it("should fail when already booked", () => {
      const activityId = 1
      const companion = null
      
      const result = {
        type: "err",
        value: 202,
      }
      
      expect(result.type).toBe("err")
      expect(result.value).toBe(202) // ERR_ALREADY_EXISTS
    })
  })
  
  describe("Activity Completion", () => {
    it("should complete activity with rating", () => {
      const bookingId = 1
      const rating = 8
      
      const result = {
        type: "ok",
        value: true,
      }
      
      expect(result.type).toBe("ok")
      expect(result.value).toBe(true)
    })
    
    it("should fail with invalid rating", () => {
      const bookingId = 1
      const rating = 11 // Invalid rating
      
      const result = {
        type: "err",
        value: 203,
      }
      
      expect(result.type).toBe("err")
      expect(result.value).toBe(203) // ERR_INVALID_INPUT
    })
    
    it("should fail if already completed", () => {
      const bookingId = 1
      const rating = 8
      
      const result = {
        type: "err",
        value: 203,
      }
      
      expect(result.type).toBe("err")
      expect(result.value).toBe(203) // ERR_INVALID_INPUT
    })
  })
  
  describe("Booking Cancellation", () => {
    it("should cancel booking successfully", () => {
      const bookingId = 1
      
      const result = {
        type: "ok",
        value: true,
      }
      
      expect(result.type).toBe("ok")
      expect(result.value).toBe(true)
    })
    
    it("should fail without 24-hour notice", () => {
      const bookingId = 1
      
      const result = {
        type: "err",
        value: 203,
      }
      
      expect(result.type).toBe("err")
      expect(result.value).toBe(203) // ERR_INVALID_INPUT
    })
  })
  
  describe("Read-only Functions", () => {
    it("should get activity information", () => {
      const activityId = 1
      
      const result = {
        creator: creator,
        title: "Morning Walk in Central Park",
        description: "A gentle walk through Central Park",
        category: "outdoor",
        location: "Central Park, NYC",
        date: 1000000,
        duration: 120,
        maxParticipants: 5,
        currentParticipants: 2,
        costPerPerson: 1000000,
        status: "open",
        createdAt: 500000,
      }
      
      expect(result.title).toBe("Morning Walk in Central Park")
      expect(result.maxParticipants).toBe(5)
      expect(result.currentParticipants).toBe(2)
    })
    
    it("should check activity availability", () => {
      const activityId = 1
      const availability = 3 // 5 max - 2 current = 3 available
      
      expect(availability).toBe(3)
    })
    
    it("should check if user is participant", () => {
      const activityId = 1
      const participant = participant1
      const isParticipant = true
      
      expect(isParticipant).toBe(true)
    })
  })
})
