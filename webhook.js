verifyAppleSubscription: async (req, res, next) => {
	try {
		const { signedPayload } = req.body

		if (!signedPayload) {
			throw new CustomError('Missing signedPayload', 400)
		}

		// Giải mã JWT từ signedPayload
		const decodedPayload = jwt.decode(signedPayload, { complete: true })

		if (!decodedPayload) {
			throw new CustomError('Invalid signedPayload', 400)
		}

		// console.log('Decoded payload:', JSON.stringify(decodedPayload, null, 2))

		const payload = decodeAppleJWT(
			decodedPayload.payload.data.signedTransactionInfo
		)

		// console.log('Payload:', JSON.stringify(payload, null, 2))

		const notificationType = decodedPayload.payload.notificationType
		const subscriptionStatus = decodedPayload.payload.data.status

		const transactionId = payload.transactionId
		const originalTransactionId = payload.originalTransactionId.toString()

		logger(
			`[APPLE STORE SERVER NOTIFICATION]🔔 Nhận thông báo: ${notificationType} - Transaction ID: ${transactionId} - Subscription Status: ${subscriptionStatus} - OriginalTransactionId: ${originalTransactionId} - Payload: ${payload.productId}`
		)

		let create = true

		if (notificationType !== 'SUBSCRIBED' && notificationType !== 'DID_RENEW') {
			// `[Apple Store Server Notification] Người dùng thay đổi thông tin đăng ký trên Itune`
		}

		// Cập nhật trạng thái subscription trong database
		if (notificationType === 'SUBSCRIBED') {
			// `[Apple Store Server Notification] Người dùng đăng ký mới, kết hợp với phần verfiy của server`
		}

		if (
			notificationType === 'DID_RENEW'
			// notificationType === 'DID_CHANGE_RENEWAL_PREF' ||
			// notificationType === 'DID_CHANGE_RENEWAL_STATUS'
		) {
			create = false

			// `[Apple Store Server Notification] Người dùng gia hạn gói VIP thành công`
		}
		if (notificationType === 'EXPIRED') {
			create = false

			// `[Apple Store Server Notification] Người dùng đã hủy gói VIP`
		}
	} catch (error) {
		logger.error(
			`[APPLE STORE SERVER NOTIFICATION] Lỗi khi xử lý thông báo: ${error.message}`
		)
		return res.status(200).json({
			status: 'error',
			message: 'Error processing Apple subscription notification',
		})

		// lưu ý phải trả về 200 OK cho Apple để tránh bị gửi lại thông báo
	}
}

function decodeAppleJWT(token) {
	try {
		const decoded = jwt.decode(token, { complete: true })
		return decoded?.payload
	} catch (error) {
		console.error('JWT decode error:', error)
		return null
	}
}
