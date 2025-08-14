verifyPurchaseToken: async (req, res, next) => {
	try {
		const { receipt, fcmToken, device, socketId, restore } = req.body

		console.log({ receipt, fcmToken, device, socketId })

		// Chọn đường dẫn sandbox hoặc production
		const APPLE_URL = 'https://buy.itunes.apple.com/verifyReceipt'
		const SANDBOX_URL = 'https://sandbox.itunes.apple.com/verifyReceipt'

		const response = await fetch(APPLE_URL, {
			method: 'POST',
			body: JSON.stringify({
				'receipt-data': receipt,
				password: process.env.APPLE_SHARED_SECRET, // Thay bằng shared secret của bạn
			}),
		})

		let data = await response.json()

		// Nếu transaction ở môi trường sandbox, thử gửi lại ở SANDBOX_URL
		if (data.status === 21007) {
			const sandboxResponse = await fetch(SANDBOX_URL, {
				method: 'POST',
				body: JSON.stringify({
					'receipt-data': receipt,
					password: process.env.APPLE_SHARED_SECRET, // Thay bằng shared secret của bạn
				}),
			})

			data = await sandboxResponse.json()
		}

		// console.log(JSON.stringify(data, null, 2))

		// Lấy originalTransactionId
		let originalTransactionId = null

		let productId = null

		if (data.receipt && data.receipt.in_app && data.receipt.in_app.length > 0) {
			originalTransactionId = data.receipt.in_app[0].original_transaction_id
			productId = data.receipt.in_app[0].product_id
		}

		if (!originalTransactionId || !productId) {
			throw new CustomError(
				'Có lỗi xảy ra.\nXin lỗi vì sự bất tiện này\nVui lòng liên hệ hỗ trợ.',
				400
			)
		}

		// dùng originalTransactionId để kiểm tra trong database
		// dùng productId để xác định gói dịch vụ
	} catch (error) {
		console.error('Error verifying purchase token:', error)
		return next(
			new CustomError(
				'Không thể xác minh giao dịch của bạn.\nVui lòng thử lại sau.',
				500
			)
		)
	}
}
