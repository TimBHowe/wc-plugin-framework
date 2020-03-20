<?php
/**
 * WooCommerce Plugin Framework
 *
 * This source file is subject to the GNU General Public License v3.0
 * that is bundled with this package in the file license.txt.
 * It is also available through the world-wide-web at this URL:
 * http://www.gnu.org/licenses/gpl-3.0.html
 * If you did not receive a copy of the license and are unable to
 * obtain it through the world-wide-web, please send an email
 * to license@skyverge.com so we can send you a copy immediately.
 *
 * DISCLAIMER
 *
 * Do not edit or add to this file if you wish to upgrade the plugin to newer
 * versions in the future. If you wish to customize the plugin for your
 * needs please refer to http://www.skyverge.com
 *
 * @package   SkyVerge/WooCommerce/Plugin/Classes
 * @author    SkyVerge
 * @copyright Copyright (c) 2013-2020, SkyVerge, Inc.
 * @license   http://www.gnu.org/licenses/gpl-3.0.html GNU General Public License v3.0
 */

namespace SkyVerge\WooCommerce\PluginFramework\v5_6_1\REST_API\Controllers;

use SkyVerge\WooCommerce\PluginFramework\v5_6_1\Settings_API\Abstract_Settings;

defined( 'ABSPATH' ) or exit;

if ( ! class_exists( '\\SkyVerge\\WooCommerce\\PluginFramework\\v5_6_1\\REST_API\\Controllers\\Settings' ) ) :

/**
 * The settings controller class.
 *
 * @since x.y.z
 */
class Settings extends \WP_REST_Controller {


	/** @var Abstract_Settings settings handler */
	protected $settings;


	/**
	 * Settings constructor.
	 *
	 * @since x.y.z
	 *
	 * @param Abstract_Settings $settings settings handler
	 */
	public function __construct( Abstract_Settings $settings ) {

		$this->settings = $settings;
		$this->namespace = 'wc/v3';

		// TODO: set $this->rest_base when Abstract_Settings has a get_id() method
	}


}

endif;
