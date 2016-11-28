###
 WooCommerce Apple Pay Handler
 Version 4.6.0-dev

 Copyright (c) 2016, SkyVerge, Inc.
 Licensed under the GNU General Public License v3.0
 http://www.gnu.org/licenses/gpl-3.0.html
###

jQuery( document ).ready ($) ->

	"use strict"

	# The WooCommerce Apple Pay handler base class.
	#
	# @since 4.6.0-dev
	class window.SV_WC_Apple_Pay_Handler


		# Constructs the handler.
		#
		# @since 4.6.0-dev
		constructor: (args) ->

			@params = sv_wc_apple_pay_params

			@payment_request = args.payment_request

			if this.is_available()

				this.init()


		# Determines if Apple Pay is available.
		#
		# @since 4.6.0-dev
		# @return bool
		is_available: ->

			return false unless window.ApplePaySession

			ApplePaySession.canMakePaymentsWithActiveCard( @params.merchant_id ).then ( canMakePayments ) =>

				return canMakePayments


		# Initializes the handler.
		#
		# @since 4.6.0-dev
		init: ->

			@buttons = $( '.sv-wc-apple-pay-button' )

			if @payment_request
				@buttons.show().prop( 'disabled', false )

			$( document.body ).on 'click', '.sv-wc-apple-pay-button:not([disabled])', ( e ) =>

				e.preventDefault()

				this.block_ui()

				try

					@session = new ApplePaySession( 1, @payment_request )

					@session.onvalidatemerchant = ( event ) => this.on_validate_merchant( event )

					@session.onpaymentauthorized = ( event ) => this.on_payment_authorized( event )

					@session.oncancel = ( event ) => this.on_cancel_payment( event )

					@session.begin()

				catch error

					this.fail_payment( error )


		# Resets the payment request via AJAX.
		#
		# Extending handlers can call this on change events to refresh the data.
		#
		# @since 4.6.0-dev
		reset_payment_request: ( data = {} ) =>

			this.block_ui()

			this.get_payment_request( data ).then ( response ) =>

				@payment_request = $.parseJSON( response )

				@buttons.show().prop( 'disabled', false )

				this.unblock_ui()

			, ( response ) =>

				console.log '[Apple Pay Error] ' + response

				@buttons.prop( 'disabled', true )

				this.unblock_ui()


		# Gets the payment request via AJAX.
		#
		# @since 4.6.0-dev
		get_payment_request: ( data ) => new Promise ( resolve, reject ) =>

			base_data = {
				'action': 'sv_wc_apple_pay_get_payment_request'
				'type'  : @type
			}

			$.extend data, base_data

			# retrieve a payment request object
			$.post @params.ajax_url, data, ( response ) =>

				if response.result is 'success'
					resolve response.request
				else
					reject response.message


		# The callback for after the merchant data is validated.
		#
		# @since 4.6.0-dev
		on_validate_merchant: ( event ) =>

			this.validate_merchant( event.validationURL ).then ( merchant_session ) =>

				merchant_session = $.parseJSON( merchant_session )

				@session.completeMerchantValidation( merchant_session )

			, ( error ) =>

				@session.abort()

				this.fail_payment 'Merchant could no be validated. ' + error


		# Validates the merchant data.
		#
		# @since 4.6.0-dev
		# @return object
		validate_merchant: ( url ) => new Promise ( resolve, reject ) =>

			data = {
				'action':      'sv_wc_apple_pay_validate_merchant',
				'nonce':       @params.validate_nonce,
				'merchant_id': @params.merchant_id,
				'url':         url
			}

			# retrieve a payment request object
			$.post @params.ajax_url, data, ( response ) =>

				if response.result is 'success'
					resolve response.merchant_session
				else
					reject response.message


		# The callback for after the payment data is authorized.
		#
		# @since 4.6.0-dev
		on_payment_authorized: ( event ) =>

			this.process_authorization( event.payment ).then ( response ) =>

				this.set_payment_status( response.result )

				this.complete_purchase( response )

			, ( error ) =>

				this.set_payment_status( false )

				this.fail_payment 'Payment could no be processed. ' + error


		# Processes the transaction data.
		#
		# @since 4.6.0-dev
		process_authorization: ( payment ) => new Promise ( resolve, reject ) =>

			data = {
				action:  'sv_wc_apple_pay_process_payment',
				nonce:   @params.process_nonce,
				type:    @type,
				payment: JSON.stringify( payment )
			}

			$.post @params.ajax_url, data, ( response ) =>

				if response.result is 'success'
					resolve response
				else
					reject response.message


		# The callback for when the payment card is cancelled/dismissed.
		#
		# @since 4.6.0-dev
		on_cancel_payment: ( event ) =>

			this.unblock_ui()


		# Completes the purchase based on the gateway result.
		#
		# @since 4.6.0-dev
		complete_purchase: ( response ) ->

			window.location = response.redirect


		# Fails the purchase based on the gateway result.
		#
		# @since 4.6.0-dev
		fail_payment: ( error ) ->

			console.log '[Apple Pay Error] ' + error

			this.unblock_ui()

			this.render_errors( [ @params.generic_error ] )


		# Sets the Apple Pay payment status depending on the gateway result.
		#
		# @since 4.6.0-dev
		set_payment_status: ( result ) ->

			if result is 'success'
				status = ApplePaySession.STATUS_SUCCESS
			else
				status = ApplePaySession.STATUS_FAILURE

			@session.completePayment( status )


		# Renders any new errors and bring them into the viewport.
		#
		# @since 4.6.0-dev
		render_errors: ( errors ) ->

			# hide and remove any previous errors
			$( '.woocommerce-error, .woocommerce-message' ).remove()

			# add errors
			@ui_element.prepend '<ul class="woocommerce-error"><li>' + errors.join( '</li><li>' ) + '</li></ul>'

			# unblock UI
			@ui_element.removeClass( 'processing' ).unblock()

			# scroll to top
			$( 'html, body' ).animate( { scrollTop: @ui_element.offset().top - 100 }, 1000 )


		# Blocks the payment form UI.
		#
		# @since 4.6.0-dev
		block_ui: -> @ui_element.block( message: null, overlayCSS: background: '#fff', opacity: 0.6 )


		# Unblocks the payment form UI.
		#
		# @since 4.6.0-dev
		unblock_ui: -> @ui_element.unblock()


	# The WooCommerce Apple Pay cart handler class.
	#
	# @since 4.6.0-dev
	class window.SV_WC_Apple_Pay_Cart_Handler extends SV_WC_Apple_Pay_Handler


		# Constructs the handler.
		#
		# @since 4.6.0-dev
		constructor: (args) ->

			@type = 'cart'

			@ui_element = $( '.cart_totals' )

			super(args)


		init: =>

			super()

			# re-init if the cart totals are updated
			$( document.body ).on 'updated_cart_totals', =>

				@ui_element = $( '.cart_totals' )

				@buttons = $( '.sv-wc-apple-pay-button' )

				@buttons.show()

				this.reset_payment_request()


	# The WooCommerce Apple Pay checkout handler class.
	#
	# @since 4.6.0-dev
	class window.SV_WC_Apple_Pay_Checkout_Handler extends SV_WC_Apple_Pay_Handler


		# Constructs the handler.
		#
		# @since 4.6.0-dev
		constructor: (args) ->

			@type = 'checkout'

			@ui_element = $( 'form.woocommerce-checkout' )

			super(args)


		init: =>

			super()

			# re-init if the cart totals are updated
			$( document.body ).on 'updated_checkout', =>

				this.reset_payment_request()


	# The WooCommerce Apple Pay product handler class.
	#
	# @since 4.6.0-dev
	class window.SV_WC_Apple_Pay_Product_Handler extends SV_WC_Apple_Pay_Handler


		# Constructs the handler.
		#
		# @since 4.6.0-dev
		constructor: (args) ->

			@type = 'product'

			@ui_element = $( 'form.cart' )

			super(args)
