@php
    $url = '';

    $MyNavBar = \Menu::make('MenuList', function ($menu) use($url) {
        // Dashboard (Standalone)
        $menu->raw('<h6>'.__('message.main_menu').'</h6>');
        $menu->add('<span>'.__('message.dashboard').'</span>', ['route' => 'home'])
            ->prepend('<i class="fas fa-home"></i>')
            ->link->attr(['class' => '', 'title' => __('message.dashboard'), 'data-toggle' => 'tooltip', 'data-placement' => 'right']);

        // Dispatch (Standalone)
        $menu->add('<span>'.__('message.dispatch').'</span>', ['class' => '', 'route' => 'dispatch.create'])
            ->prepend('<i class="fa fa-plus"></i>')
            ->data('permission', 'dispatch add')
            ->link->attr(['class' => '', 'title' => __('message.dispatch'), 'data-toggle' => 'tooltip', 'data-placement' => 'right']);

        // Location Management Heading
        if (collect(['region list', 'managezone-list', 'airport-list', 'driver location'])->some(fn($perm) => auth()->user()->can($perm))) {
            $menu->raw('<h6>' . __('message.location_management') . '</h6>');
        }        

        // Region
        $menu->add('<span>'.__('message.region').'</span>', ['route' => 'region.index'])
            ->prepend('<i class="fas fa-globe"></i>')
            ->nickname('region')
            ->data('permission', 'region list')
            ->link->attr(['class' => '', 'title' => __('message.region'), 'data-toggle' => 'tooltip', 'data-placement' => 'right']);

        // Manage Zone
        $menu->add('<span>'.__('message.manage_zone').'</span>', ['route' => 'managezone.index'])
            ->prepend('<i class="fas fa-map-marker-alt"></i>')
            ->nickname('managezone')
            ->data('permission', 'managezone-list')
            ->link->attr(['class' => '', 'title' => __('message.manage_zone'), 'data-toggle' => 'tooltip', 'data-placement' => 'right']);

        // Airport
        $menu->add('<span>'.__('message.airport').'</span>', ['route' => 'airport.index'])
            ->prepend('<i class="fas fa-plane-departure"></i>')
            ->nickname('airport')
            ->data('permission', 'airport-list')
            ->link->attr(['class' => '', 'title' => __('message.airport'), 'data-toggle' => 'tooltip', 'data-placement' => 'right']);

        // Driver Location
        $menu->add('<span>'.__('message.driver_location').'</span>', ['route' => 'map'])
            ->prepend('<i class="fas fa-map"></i>')
            ->nickname('map')
            ->data('permission', 'driver location')
            ->link->attr(['class' => '  ', 'title' => __('message.driver_location'), 'data-toggle' => 'tooltip', 'data-placement' => 'right']);

        // User Management Heading
        if (collect(['rider list', 'driver list', 'driverdocument list','document list','sub_admin-list'])->some(fn($perm) => auth()->user()->can($perm))) {
            $menu->raw('<h6>' . __('message.user_management') . '</h6>');
        }

        // Customer Management Sub-Menu
        $menu->add('<span>'.__('message.customer_management').'</span>', ['class' => ''])
            ->prepend('<i class="fas fa-chalkboard-teacher"></i>')
            ->nickname('user')
            ->data('permission', 'rider list')
            ->link->attr(['class' => ''])
            ->href('#user');

            $menu->user->add('<span>'.__('message.list_form_title',['form' => __('message.customer')]).'</span>', ['class' => 'sidebar-layout' ,'route' => 'rider.index'])
                ->data('permission', 'rider list')
                ->prepend('<i class="fas fa-users"></i>')
                ->link->attr(['class' => '','title' => __('message.user'),'data-toggle' => 'tooltip','data-placement' => 'right']);
                
            $menu->user->add('<span>'.__('message.list_form_title',['form' => __('message.driver')]).'</span>', ['class' => 'sidebar-layout' ,'route' => 'driver.index'])
                ->data('permission', 'driver list')
                ->prepend('<i class="fas fa-chalkboard-teacher"></i>')
                ->link->attr(['class' => '','title' => __('message.driver'),'data-toggle' => 'tooltip','data-placement' => 'right']);

            $menu->user->add('<span>'.__('message.manage_driver_document').'</span>', ['class' => ( request()->is('driverdocument') || request()->is('driverdocument/*') ) ? 'sidebar-layout active' : 'sidebar-layout', 'route' => 'driverdocument.index'])
                ->data('permission', ['driverdocument list'])
                ->prepend('<i class="fas fa-paperclip"></i>')
                ->link->attr(['class' => '','title' => __('message.manage_driver_document'),'data-toggle' => 'tooltip','data-placement' => 'right']);

            $menu->user->add('<span>'.__('message.document').'</span>', ['route' => 'document.index'])
                ->prepend('<i class="fas fa-print"></i>')
                ->nickname('document')
                ->data('permission', 'document list')
                ->link->attr(['class' => '', 'title' => __('message.document'), 'data-toggle' => 'tooltip', 'data-placement' => 'right']);

        // Sub-Admin
        $menu->add('<span>'.__('message.sub_admin').'</span>', ['route' => 'sub-admin.index'])
            ->prepend('<i class="fa fa-user-lock"></i>')
            ->nickname('sub_admin')
            ->data('permission', 'sub_admin-list')
            ->link->attr(['class' => '', 'title' => __('message.sub_admin'), 'data-toggle' => 'tooltip', 'data-placement' => 'right']);

        // Ride Management Heading
        if (collect(['riderequest list', 'coupon list'])->some(fn($perm) => auth()->user()->can($perm))) {
            $menu->raw('<h6>' . __('message.ride_management') . '</h6>');
        }
        
        // Ride Request
        $count = App\Models\RideRequest::myRide()->where('status', 'pending')->count();
        $new_ride_request = $count > 99 ? '99+' : $count;
        $menu->add('<span>'.__('message.riderequest').'</span>'.($new_ride_request > 0 ? '<span class="badge badge-primary ride-badge" style="padding-left:6px;padding-right:6px;">'.$new_ride_request.'</span>' : ''), ['route' => 'riderequest.index'])
            ->prepend('<i class="fas fa-car-side"></i>')
            ->nickname('riderequest')
            ->data('permission', 'riderequest list')
            ->link->attr(['class' => '', 'title' => __('message.riderequest'), 'data-toggle' => 'tooltip', 'data-placement' => 'right']);
        

        // Service Management Heading
        if (collect(['service list', 'special_rate add', 'special_rate edit'])->some(fn($perm) => auth()->user()->can($perm))) {
            $menu->raw('<h6>' . __('message.service_management') . '</h6>');
        } 

        // Service Sub-Menu
        $menu->add('<span>'.__('message.service').'</span>', [ 'class' => '', 'route' => 'service.index'])
            ->prepend('<i class="fas fa-taxi"></i>')
            ->nickname('service')
            ->data('permission', 'service list')
            ->link->attr(['class' => '','title' => __('message.service'),'data-toggle' => 'tooltip','data-placement' => 'right'])
            ->href('#service');

            $menu->service->add('<span>'.__('message.list_form_title',['form' => __('message.service')]).'</span>', ['class' => 'sidebar-layout' ,'route' => 'service.index'])
                ->data('permission', 'service list')
                ->prepend('<i class="fas fa-list"></i>')
                ->link->attr(['class' => '','title' => __('message.service'),'data-toggle' => 'tooltip','data-placement' => 'right']);

            $menu->service->add('<span>'.__('message.special_rates').'</span>', ['class' => request()->is('service/*/edit') ? 'sidebar-layout active' : 'sidebar-layout','route' => 'specialservices.index'])
                ->data('permission', [ 'special_rate add', 'special_rate edit'])
                ->prepend('<i class="fas fa-tags"></i>')
                ->link->attr(['class' => '','title' => __('message.special_rates'),'data-toggle' => 'tooltip','data-placement' => 'right']);

        
        // Corporate Management Heading
        if (collect(['company_type-list', 'corporate-list', 'driverdocument list','document list','sub_admin-list'])->some(fn($perm) => auth()->user()->can($perm))) {
            $menu->raw('<h6>' . __('message.corporate_management') . '</h6>');
        }

        // Company Type
        $menu->add('<span>'.__('message.company_type').'</span>', ['route' => 'comapanytype.index'])
            ->prepend('<i class="fas fa-landmark"></i>')
            ->nickname('company_type')
            ->data('permission', 'company_type-list')
            ->link->attr(['class' => '', 'title' => __('message.company_type'), 'data-toggle' => 'tooltip', 'data-placement' => 'right']);

        // Corporate
        $menu->add('<span>'.__('message.corporate').'</span>', ['route' => 'corporate.index'])
            ->prepend('<i class="fas fa-hotel"></i>')
            ->nickname('corporate')
            ->data('permission', 'corporate-list')
            ->link->attr(['class' => '', 'title' => __('message.corporate'), 'data-toggle' => 'tooltip', 'data-placement' => 'right']);

        $menu->add('<span>'.__('message.manage_corporate_document').'</span>', ['route' => 'corporatedocument.index'])
            ->prepend('<i class="fas fa-hotel"></i>')
            ->nickname('manage_corporate_document')
            ->data('permission', 'manage_corporate_document-list')
            ->link->attr(['class' => '', 'title' => __('message.manage_corporate_document'), 'data-toggle' => 'tooltip', 'data-placement' => 'right']);

        // Financial Management Heading
        if (collect(['payment-list', 'online-payment-list', 'cash-payment-list','wallet-payment-list','withdrawrequest list','additionalfees list'])->some(fn($perm) => auth()->user()->can($perm))) {
            $menu->raw('<h6>' . __('message.financial_management') . '</h6>');
        }

        // Payment Sub-Menu
        $menu->add('<span>'.__('message.payment').'</span>', ['class' => ''])
            ->prepend('<i class="ri-secure-payment-fill" style="font-size: 22px;"></i>')
            ->nickname('payment')
            ->data('permission', 'payment-list')
            ->link->attr(['class' => '','title' => __('message.payment'),'data-toggle' => 'tooltip','data-placement' => 'right'])
            ->href('#payment');

            $menu->payment->add('<span>'. __('message.online_payment').'</span>', ['class' => 'sidebar-layout' ,'route' => ['payment.index','payment_type'=>'online']])
                ->data('permission', 'online-payment-list')
                ->prepend('<i class="fas fa-money-check"></i>')
                ->link->attr(['class' => '','title' => __('message.online_payment'),'data-toggle' => 'tooltip','data-placement' => 'right']);

            $menu->payment->add('<span>'.__('message.cash_payment').'</span>', ['class' => 'sidebar-layout' ,'route' => ['payment.index','payment_type'=>'cash']])
                ->data('permission', 'cash-payment-list')
                ->prepend('<i class="fas fa-money-bill-wave"></i>')
                ->link->attr(['class' => '','title' => __('message.cash_payment'),'data-toggle' => 'tooltip','data-placement' => 'right']);

            $menu->payment->add('<span>'.__('message.wallet_payment').'</span>', ['class' => 'sidebar-layout' ,'route' => ['payment.index','payment_type'=>'wallet']])
                ->data('permission', 'wallet-payment-list')
                ->prepend('<i class="fas fa-wallet"></i>')
                ->link->attr(['class' => '','title' => __('message.wallet_payment'),'data-toggle' => 'tooltip','data-placement' => 'right']);
            
            // Withdraw Request Sub-Menu
        $pending_withdraw_request = App\Models\WithdrawRequest::where('status',0)->count();
        $menu->add('<span>'.__('message.withdrawrequest').'</span>'.($pending_withdraw_request > 0 ? '<span class="badge badge-dark ride-badge">'.$pending_withdraw_request.'</span>' : ''), ['class' => ''])
            ->prepend('<i class="fas fa-money-check"></i>')
            ->nickname('withdrawrequest')
            ->data('permission', 'withdrawrequest list')
            ->link->attr(['class' => '','title' => __('message.withdrawrequest'),'data-toggle' => 'tooltip','data-placement' => 'right'])
            ->href('#withdrawrequest');

            $menu->withdrawrequest->add('<span>'.__('message.all').'</span>', ['class' => 'sidebar-layout' ,'route' => ['withdrawrequest.index','withdraw_type' => 'all']])
                ->data('permission', 'withdrawrequest list')
                ->prepend('<i class="fas fa-list"></i>')
                ->link->attr(['class' => '','title' => __('message.all') .' '. __('message.withdrawrequest'),'data-toggle' => 'tooltip','data-placement' => 'right']);

            $menu->withdrawrequest->add('<span>'.__('message.list_form_title',['form' => __('message.pending')]).'</span>', ['class' => 'sidebar-layout' ,'route' => ['withdrawrequest.index','withdraw_type'=>'pending']])
                ->data('permission', 'withdrawrequest list')
                ->prepend('<i class="fas fa-history"></i>'.($pending_withdraw_request > 0 ? '<span class="badge badge-dark ride-badge">'.$pending_withdraw_request.'</span>' : ''))
                ->link->attr(['class' => '','title' => __('message.pending') .' '. __('message.withdrawrequest'),'data-toggle' => 'tooltip','data-placement' => 'right']);

            $menu->withdrawrequest->add('<span>'.__('message.list_form_title',['form' => __('message.approved')]).'</span>', ['class' => 'sidebar-layout' ,'route' => ['withdrawrequest.index','withdraw_type'=>'approved']])
                ->data('permission', 'withdrawrequest list')
                ->prepend('<i class="fas fa-clipboard-check"></i>')
                ->link->attr(['class' => '','title' => __('message.approved') .' '. __('message.withdrawrequest'),'data-toggle' => 'tooltip','data-placement' => 'right']);

            $menu->withdrawrequest->add('<span>'.__('message.list_form_title',['form' => __('message.decline')]).'</span>', ['class' => 'sidebar-layout' ,'route' => ['withdrawrequest.index','withdraw_type'=>'decline']])
                ->data('permission', 'withdrawrequest list')
                ->prepend('<i class="fas fa-ban"></i>')
                ->link->attr(['class' => '','title' => __('message.decline') .' '. __('message.withdrawrequest'),'data-toggle' => 'tooltip','data-placement' => 'right']);
        
        // Additional Fees
        $menu->add('<span>'.__('message.additionalfees').'</span>', ['route' => 'additionalfees.index'])
            ->prepend('<i class="fas fa-file-invoice-dollar"></i>')
            ->nickname('additionalfees')
            ->data('permission', 'additionalfees list')
            ->link->attr(['class' => '', 'title' => __('message.additionalfees'), 'data-toggle' => 'tooltip', 'data-placement' => 'right']);
        
        // Coupon
        $menu->add('<span>'.__('message.coupon').'</span>', ['route' => 'coupon.index'])
            ->prepend('<i class="fas fa-gift"></i>')
            ->nickname('coupon')
            ->data('permission', 'coupon list')
            ->link->attr(['class' => '', 'title' => __('message.coupon'), 'data-toggle' => 'tooltip', 'data-placement' => 'right']);
        
        // Support Management Heading
        if (collect(['complaint list', 'sos list'])->some(fn($perm) => auth()->user()->can($perm))) {
            $menu->raw('<h6>' . __('message.support_management') . '</h6>');
        }

        // Complaint
        $pending_complaint = App\Models\Complaint::where('status', 'pending')->count();
        $menu->add('<span>'.__('message.complaint').'</span>'.($pending_complaint > 0 ? '<span class="badge badge-dark ride-badge">'.$pending_complaint.'</span>' : ''), ['route' => 'complaint.index'])
            ->prepend('<i class="fas fa-file-alt"></i>')
            ->nickname('complaint')
            ->data('permission', 'complaint list')
            ->link->attr(['class' => '', 'title' => __('message.complaint'), 'data-toggle' => 'tooltip', 'data-placement' => 'right']);

        // SOS
        $menu->add('<span>'.__('message.sos').'</span>', ['route' => 'sos.index'])
            ->prepend('<i class="fas fa-address-book"></i>')
            ->nickname('sos')
            ->data('permission', 'sos list')
            ->link->attr(['class' => '', 'title' => __('message.sos'), 'data-toggle' => 'tooltip', 'data-placement' => 'right']);

        $menu->add('<span>'.__('message.manage_cancelled_reason').'</span>', ['route' => 'cancelledreason.index'])
            ->prepend('<i class="fas fa-landmark"></i>')
            ->nickname('company_type')
            ->data('permission', 'cancelled_reason-list')
            ->link->attr(['class' => '', 'title' => __('message.manage_cancelled_reason'), 'data-toggle' => 'tooltip', 'data-placement' => 'right']);

        $menu->add('<span>'.__('message.reference_program').'</span>', ['route' => 'reference-list'])
            ->prepend('<i class="fas fa-handshake"></i>')
            ->nickname('faq')
            ->data('permission', 'reference_program-list')
            ->link->attr(['class' => '', 'title' => __('message.reference_program'), 'data-toggle' => 'tooltip', 'data-placement' => 'right']);

        // Notification Management Heading
        if (collect(['pushnotification list', 'mail_template-list','sms_template-list'])->some(fn($perm) => auth()->user()->can($perm))) {
            $menu->raw('<h6>' . __('message.notification_management') . '</h6>');
        }
        
        // Push Notification
        $menu->add('<span>'.__('message.pushnotification').'</span>', ['route' => 'pushnotification.index'])
            ->prepend('<i class="fas fa-bullhorn"></i>')
            ->nickname('pushnotification')
            ->data('permission', 'pushnotification list')
            ->link->attr(['class' => '', 'title' => __('message.pushnotification'), 'data-toggle' => 'tooltip', 'data-placement' => 'right']);
        
        // Mail Template Sub-Menu
        $menu->add('<span>'.__('message.mail_template',['name' => '']).'</span>', ['class' => ''])
            ->prepend('<i class="ri-mail-send-fill"></i>')
            ->nickname('mail_template')
            ->data('permission', 'mail_template-list')
            ->link->attr(['class' => '','title' => __('message.mail_template'),'data-toggle' => 'tooltip','data-placement' => 'right'])
            ->href('#mail_template');

            $menu->mail_template->add('<span>'.__('message.new_ride_requested').'</span>', ['class' => 'sidebar-layout' ,'route' => ['mail-template.index','type'=>'new_ride_requested']])
                ->data('permission', 'mail_template-list')
                ->prepend('<i class="fas fa-map-marked-alt"></i>')
                ->link->attr(['class' => '','title' => __('message.new_ride_requested'),'data-toggle' => 'tooltip','data-placement' => 'right']);

            $menu->mail_template->add('<span>'.__('message.accepted').'</span>', ['class' => 'sidebar-layout' ,'route' => ['mail-template.index','type'=>'accepted']])
                ->data('permission', 'mail_template-list')
                ->prepend('<i class="fas fa-calendar-check"></i>')
                ->link->attr(['class' => '','title' => __('message.accepted'),'data-toggle' => 'tooltip','data-placement' => 'right']);
                
            /*$menu->mail_template->add('<span>'.__('message.bid_placed').'</span>', ['class' => 'sidebar-layout' ,'route' => ['mail-template.index','type'=>'bid_placed']])
                ->data('permission', 'mail_template-list')
                ->prepend('<i class="fas fa-funnel-dollar"></i>')
                ->link->attr(['class' => '','title' => __('message.bid_placed'),'data-toggle' => 'tooltip','data-placement' => 'right']);

            $menu->mail_template->add('<span>'.__('message.bid_accepted').'</span>', ['class' => 'sidebar-layout' ,'route' => ['mail-template.index','type'=>'bid_accepted']])
                ->data('permission', 'mail_template-list')
                ->prepend('<i class="fas fa-check-double"></i>')
                ->link->attr(['class' => '','title' => __('message.bid_accepted'),'data-toggle' => 'tooltip','data-placement' => 'right']);

            $menu->mail_template->add('<span>'.__('message.bid_rejected').'</span>', ['class' => 'sidebar-layout' ,'route' => ['mail-template.index','type'=>'bid_rejected']])
                ->data('permission', 'mail_template-list')
                ->prepend('<i class="fas fa-user-times"></i>')
                ->link->attr(['class' => '','title' => __('message.bid_rejected'),'data-toggle' => 'tooltip','data-placement' => 'right']);

            $menu->mail_template->add('<span>'.__('message.arriving').'</span>', ['class' => 'sidebar-layout' ,'route' => ['mail-template.index','type'=>'arriving']])
                ->data('permission', 'mail_template-list')
                ->prepend('<i class="fas fa-plane-arrival"></i>')
                ->link->attr(['class' => '','title' => __('message.arriving'),'data-toggle' => 'tooltip','data-placement' => 'right']);

            $menu->mail_template->add('<span>'.__('message.arrived').'</span>', ['class' => 'sidebar-layout' ,'route' => ['mail-template.index','type'=>'arrived']])
                ->data('permission', 'mail_template-list')
                ->prepend('<i class="fas fa-car-side"></i>')
                ->link->attr(['class' => '','title' => __('message.arrived'),'data-toggle' => 'tooltip','data-placement' => 'right']);*/

            $menu->mail_template->add('<span>'.__('message.in_progress').'</span>', ['class' => 'sidebar-layout' ,'route' => ['mail-template.index','type'=>'in_progress']])
                ->data('permission', 'mail_template-list')
                ->prepend('<i class="fas fa-hourglass-half"></i>')
                ->link->attr(['class' => '','title' => __('message.in_progress'),'data-toggle' => 'tooltip','data-placement' => 'right']);

            $menu->mail_template->add('<span>'.__('message.cancelled').'</span>', ['class' => 'sidebar-layout' ,'route' => ['mail-template.index','type'=>'cancelled']])
                ->data('permission', 'mail_template-list')
                ->prepend('<i class="far fa-times-circle"></i>')
                ->link->attr(['class' => '','title' => __('message.cancelled'),'data-toggle' => 'tooltip','data-placement' => 'right']);

            $menu->mail_template->add('<span>'.__('message.driver_cancelled').'</span>', ['class' => 'sidebar-layout' ,'route' => ['mail-template.index','type'=>'driver_cancelled']])
                ->data('permission', 'mail_template-list')
                ->prepend('<i class="fas fa-user-slash"></i>')
                ->link->attr(['class' => '','title' => __('message.driver_cancelled'),'data-toggle' => 'tooltip','data-placement' => 'right']);

            $menu->mail_template->add('<span>'.__('message.customer_cancelled').'</span>', ['class' => 'sidebar-layout' ,'route' => ['mail-template.index','type'=>'rider_cancelled']])
                ->data('permission', 'mail_template-list')
                ->prepend('<i class="fas fa-user-slash"></i>')
                ->link->attr(['class' => '','title' => __('message.rider_cancelled'),'data-toggle' => 'tooltip','data-placement' => 'right']);

            $menu->mail_template->add('<span>'.__('message.completed').'</span>', ['class' => 'sidebar-layout' ,'route' => ['mail-template.index','type'=>'completed']])
                ->data('permission', 'mail_template-list')
                ->prepend('<i class="fas fa-user-check"></i>')
                ->link->attr(['class' => '','title' => __('message.completed'),'data-toggle' => 'tooltip','data-placement' => 'right']);

            $menu->mail_template->add('<span>'.__('message.payment_status_message').'</span>', ['class' => 'sidebar-layout' ,'route' => ['mail-template.index','type'=>'payment_status_message']])
                ->data('permission', 'mail_template-list')
                ->prepend('<i class="fas fa-money-check-alt"></i>')
                ->link->attr(['class' => '','title' => __('message.payment_status_message'),'data-toggle' => 'tooltip','data-placement' => 'right']);

            $menu->add('<span>'.__('message.sms_templated').'</span>', ['class' => ''])
                ->prepend('<i class="far fa-comments"></i>')
                ->nickname('ridesms')
                ->data('permission', 'sms_template-list')
                ->link->attr(['class' => '','title' => __('message.sms_templated'),'data-toggle' => 'tooltip','data-placement' => 'right'])
                ->href('#ridesms');

                $menu->ridesms->add('<span>'.__('message.driver_is_arrived').'</span>', ['class' => 'sidebar-layout' ,'route' => ['ridesms.index','sms_type' => 'driver_is_arrived']])
                    ->data('permission', 'sms_template-list')
                    ->prepend('<i class="fas fa-sms"></i>')
                    ->link->attr(['class' => '','title' => __('message.driver_is_arrived'),'data-toggle' => 'tooltip','data-placement' => 'right']);            

        // Report Management Heading
        if (collect(['report list', 'adminrearning list','driverearning list','service-wise-report','corporate-report list'])->some(fn($perm) => auth()->user()->can($perm))) {
            $menu->raw('<h6>' . __('message.report_management') . '</h6>');
        }

        // Report Sub-Menu
        $menu->add('<span>'.__('message.report',['name' => '']).'</span>', ['class' => ''])
            ->prepend('<i class="far fa-copy"></i>')
            ->nickname('report')
            ->data('permission', 'report list')
            ->link->attr(['class' => '','title' => __('message.report'),'data-toggle' => 'tooltip','data-placement' => 'right'])
            ->href('#report');

            $menu->report->add('<span>'.__('message.report',['name' => __('message.admin')]).'</span>', ['class' => 'sidebar-layout' ,'route' => 'adminEarningReport'])
                    ->data('permission', 'adminrearning list')
                    ->prepend('<i class="fas fa-file-contract"></i>')
                    ->link->attr(['class' => '','title' => __('message.report',['name' => __('message.admin')]),'data-toggle' => 'tooltip','data-placement' => 'right']);

            $menu->report->add('<span>'.__('message.driver_earning').'</span>', ['class' => ( request()->is('driver-earning') || request()->is('driver-earning/*') ) ? 'sidebar-layout active' : 'sidebar-layout', 'route' => 'driver.earning.report'])
                ->data('permission', ['driverearning list'])
                ->prepend('<i class="fas fa-file-invoice-dollar"></i>')
                ->link->attr(['class' => '','title' => __('message.report',['name' => __('message.driver_earning')]),'data-toggle' => 'tooltip','data-placement' => 'right']);

            $menu->report->add('<span>'.__('message.service_wise').'</span>', ['class' => ( request()->is('service-wise') || request()->is('service-wise/*') ) ? 'sidebar-layout active' : 'sidebar-layout', 'route' => 'serviceWiseReport'])
                ->data('permission', ['service-wise-report'])
                ->prepend('<i class="fas fa-hand-holding-usd"></i>')
                ->link->attr(['class' => '','title' => __('message.report',['name' => __('message.service_wise')]),'data-toggle' => 'tooltip','data-placement' => 'right']);

            $menu->report->add('<span>'.__('message.corporate').'</span>', ['class' => ( request()->is('corporate') || request()->is('corporate/*') ) ? 'sidebar-layout active' : 'sidebar-layout', 'route' => 'corporate.report'])
                ->data('permission', ['corporate-report list'])
                ->prepend('<i class="fas fa-money-bill"></i>')
                ->link->attr(['class' => '','title' => __('message.report',['name' => __('message.corporate')]),'data-toggle' => 'tooltip','data-placement' => 'right']);

        // Page Management Heading
        if (collect(['pages', 'terms condition','privacy policy'])->some(fn($perm) => auth()->user()->can($perm))) {
            $menu->raw('<h6>' . __('message.page_management') . '</h6>');
        }

        // Pages Sub-Menu
        $menu->add('<span>'.__('message.pages').'</span>', ['class' => ''])
            ->prepend('<i class="fas fa-file"></i>')
            ->nickname('pages')
            ->data('permission', 'pages')
            ->link->attr(['class' => '','title' => __('message.pages'),'data-toggle' => 'tooltip','data-placement' => 'right'])
            ->href('#pages');

            $menu->pages->add('<span>'.__('message.terms_condition').'</span>', ['class' => 'sidebar-layout' ,'route' => 'term-condition'])
                ->data('permission', 'terms condition')
                ->prepend('<i class="fas fa-file-contract"></i>')
                ->link->attr(['class' => '','title' => __('message.terms_condition'),'data-toggle' => 'tooltip','data-placement' => 'right']);
            
            $menu->pages->add('<span>'.__('message.privacy_policy').'</span>', ['class' => 'sidebar-layout' ,'route' => 'privacy-policy'])
                ->data('permission', 'privacy policy')
                ->prepend('<i class="fas fa-user-shield"></i>')
                ->link->attr(['class' => '','title' => __('message.privacy_policy'),'data-toggle' => 'tooltip','data-placement' => 'right']);

        $menu->add('<span>'.__('message.faq').'</span>', ['route' => 'faqs.index'])
            ->prepend('<i class="fas fa-question"></i>')
            ->nickname('faq')
            ->data('permission', 'faq-list')
            ->link->attr(['class' => '', 'title' => __('message.faq'), 'data-toggle' => 'tooltip', 'data-placement' => 'right']);


        // System Settings Heading
        if (collect(['app_language_setting', 'screen-list','defaultkeyword-list','languagelist-list','languagewithkeyword-list','bulkimport-list','permission list','system setting'])->some(fn($perm) => auth()->user()->can($perm))) {
            $menu->raw('<h6>' . __('message.system_settings') . '</h6>');
        }
        // Setting
        $menu->add('<span>'.__('message.app_language_setting').'</span>', [ 'class' => ''])
            ->prepend('<i class="fa fa-language"></i>')
            ->nickname('app_language_setting')
            ->data('permission', 'app_language_setting')
            ->link->attr(['class' => '','title' => __('message.app_language_setting'),'data-toggle' => 'tooltip','data-placement' => 'right'])
            ->href('#app_language_setting');

            $menu->app_language_setting->add('<span>'.__('message.list_form_title',['form' => __('message.screen')]).'</span>', ['class' => 'sidebar-layout' ,'route' => 'screen.index'])
                ->data('permission', 'screen-list')
                ->prepend('<i class="fas fa-mobile-alt"></i>')
                ->link->attr(['class' => '','title' => __('message.screen'),'data-toggle' => 'tooltip','data-placement' => 'right']);

            $menu->app_language_setting->add('<span>'.__('message.list_form_title',['form' => __('message.default_keyword')]).'</span>', ['class' => 'sidebar-layout' ,'route' => 'defaultkeyword.index'])
                ->data('permission', 'defaultkeyword-list')
                ->prepend('<i class="fas fa-list"></i>')
                ->link->attr(['class' => '','title' => __('message.default_keyword'),'data-toggle' => 'tooltip','data-placement' => 'right']);

            $menu->app_language_setting->add('<span>'.__('message.list_form_title',['form' => __('message.language')]).'</span>', ['class' => request()->is('languagelist/*/edit') || request()->is('languagelist/create') ? 'sidebar-layout active' : 'sidebar-layout' ,'route' => 'languagelist.index'])
                ->data('permission', 'languagelist-list')
                ->prepend('<i class="fas fa-language"></i>')
                ->link->attr(['class' => '','title' => __('message.language'),'data-toggle' => 'tooltip','data-placement' => 'right']);

            $menu->app_language_setting->add('<span>'.__('message.list_form_title',['form' => __('message.language_with_keyword')]).'</span>', ['class' => 'sidebar-layout' ,'route' => 'languagewithkeyword.index'])
                ->data('permission', 'languagewithkeyword-list')
                ->prepend('<i class="fas fa-list"></i>')
                ->link->attr(['class' => '','title' => __('message.language_with_keyword'),'data-toggle' => 'tooltip','data-placement' => 'right']);

            $menu->app_language_setting->add('<span>'.__('message.list_form_title',['form' => __('message.bulk_import_langugage_data')]).'</span>', ['class' => 'sidebar-layout' ,'route' => 'bulk.language.data'])
                ->data('permission', 'bulkimport-list')
                ->prepend('<i class="fas fa-list"></i>')
                ->link->attr(['class' => '','title' => __('message.bulk_import_langugage_data'),'data-toggle' => 'tooltip','data-placement' => 'right']);

        $menu->add('<span>'.__('message.account_setting').'</span>', ['class' => ''])
            ->prepend('<i class="fas fa-users-cog"></i>')
            ->nickname('account_setting')
            ->data('permission', ['role list','permission list'])
            ->link->attr(["class" => ""])
            ->href('#account_setting');

            $menu->account_setting->add('<span>'.__('message.list_form_title',['form' => __('message.role')]).'</span>', ['class' => 'sidebar-layout' ,'route' => 'role.index'])
                ->data('permission', 'role list')
                ->prepend('<i class="fas fa-universal-access"></i>')
                ->link->attr(['class' => '','title' => __('message.role'),'data-toggle' => 'tooltip','data-placement' => 'right']);

            $menu->account_setting->add('<span>'.__('message.list_form_title',['form' => __('message.permission')]).'</span>', ['class' => 'sidebar-layout' ,'route' => 'permission.index'])
                ->data('permission', 'permission list')
                ->prepend('<i class="fas fa-key"></i>')
                ->link->attr(['class' => '','title' => __('message.permission'),'data-toggle' => 'tooltip','data-placement' => 'right']);
        
        $menu->add('<span>'.__('message.setting').'</span>', ['route' => 'setting.index'])
            ->prepend('<i class="fas fa-cogs"></i>')
            ->nickname('setting')
            ->data('permission', 'system setting')
            ->link->attr(['class' => '', 'title' => __('message.setting'), 'data-toggle' => 'tooltip', 'data-placement' => 'right']);

            if (env('ACTIVITY_LOG_ENABLED') == true) {
                $menu->add('<span>'.__('message.manage_history').'</span>', ['route' => 'activity.history'])
                ->prepend('<i class="fas fa-history"></i>')
                ->data('permission', 'system setting')
                ->link->attr(['class' => '']);
            }
        
    })->filter(function ($item) {
        return checkMenuRoleAndPermission($item);
    });
@endphp

<div class="mm-sidebar sidebar-default">
    <div class="mm-sidebar-logo d-flex align-items-center justify-content-between">
        <a href="{{ route('home') }}" class="header-logo">
            <img src="{{ getSingleMedia(appSettingData('get'),'site_logo',null) }}" class="img-fluid mode light-img rounded-normal light-logo site_logo_preview" alt="logo">
            <img src="{{ getSingleMedia(appSettingData('get'),'site_dark_logo',null) }}" class="img-fluid mode dark-img rounded-normal darkmode-logo site_dark_logo_preview" alt="dark-logo">
        </a>
        <div class="side-menu-bt-sidebar">
            <i class="fas fa-bars wrapper-menu"></i>
        </div>
    </div>
    <div class="mm-sidebar-logo d-flex mm-search-bar device-search mm-sidebar-menu-search m-auto">
        <div class="searchbox">
            <i class="ri-search-line search-link"></i>
            <input type="text" class="text search-input" placeholder="{{ __('message.search_menu') }}">
        </div>
    </div>
    <div class="data-scrollbar" data-scroll="1">
        <nav class="mm-sidebar-menu">
            <ul id="mm-sidebar-toggle" class="side-menu">
                @include(config('laravel-menu.views.bootstrap-items'), ['items' => $MyNavBar->roots()])       
            </ul>
        </nav>
        <div class="pt-5 pb-5"></div>
        <div class="pb-5"></div>
    </div>
</div>
