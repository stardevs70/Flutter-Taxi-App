<?php

use Illuminate\Database\Migrations\Migration;
use App\Helpers\SeederHelper;
use Carbon\Carbon;
use App\Models\User;

return new class extends Migration
{

    protected function shouldRun(): bool
    {
        return !User::where('email', 'admin@admin.com')->exists();
    }

    /**
     * Run the migrations.
     */
    public function up(): void
    {
        if (!$this->shouldRun()) {
            return;
        }

        $permissions = [
            [
                'name' => 'role',
                'sub_permission' => [ 'role add', 'role list'],
            ],
            [
                'name' => 'permission',
                'sub_permission' => [ 
                    'permission add', 'permission list',
                ],
            ],
            [
                'name' => 'region',
                'sub_permission' => [ 
                   'region list', 'region add', 'region edit', 'region delete',
                ],
            ],
            [
                'name' => 'service',
                'sub_permission' => [ 
                   'service list', 'service add', 'service show', 'service edit', 'service delete', 'special_rate list', 'special_rate add', 'special_rate edit', 'special_rate delete'
                ],
            ],
            [
                'name' => 'driver',
                'sub_permission' => [ 
                   'driver list', 'driver add', 'driver show', 'driver edit', 'driver delete', 'pending driver', 'driver location'
                ],
            ],
            [
                'name' => 'rider',
                'sub_permission' => [ 
                   'rider list', 'rider add', 'rider show', 'rider edit', 'rider delete'
                ],
            ],
            [
                'name' => 'riderequest',
                'sub_permission' => [ 
                   'riderequest list', 'dispatch add', 'riderequest show', 'riderequest delete'
                ],
            ],
            [
                'name' => 'document',
                'sub_permission' => [ 
                   'document list', 'document add', 'document edit', 'document delete'
                ],
            ],
            [
                'name' => 'driverdocument',
                'sub_permission' => [ 
                   'driverdocument list', 'driverdocument add',  'driverdocument edit', 'driverdocument delete'
                ],
            ],
            [
                'name' => 'coupon',
                'sub_permission' => [ 
                   'coupon list', 'coupon add',  'coupon edit', 'coupon delete'
                ],
            ],
            [
                'name' => 'additionalfees',
                'sub_permission' => [ 
                   'additionalfees list', 'additionalfees add',  'additionalfees edit', 'additionalfees delete'
                ],
            ],
            [
                'name' => 'sos',
                'sub_permission' => [ 
                   'sos list', 'sos add',  'sos edit', 'sos delete'
                ],
            ],
            [
                'name' => 'complaint',
                'sub_permission' => [ 
                   'complaint list', 'complaint add', 'complaint show',  'complaint edit', 'complaint delete'
                ],
            ],
            [
                'name' => 'pushnotification',
                'sub_permission' => [ 
                   'pushnotification list', 'pushnotification add',  'pushnotification delete'
                ],
            ],
            [
                'name' => 'pages',
                'sub_permission' => [ 
                   'terms condition', 'privacy policy', 'pages list', 'pages add', 'pages show',  'pages edit', 'pages delete'
                ],
            ],
            [
                'name' => 'report',
                'sub_permission' => [ 
                   'report list', 'driverearning list', 'adminrearning list', 'service-wise-report', 'corporate-report list'
                ],
            ],
            [
                'name' => 'app-language-setting',
                'sub_permission' => [ 
                   'screen-list', 'defaultkeyword-list', 'defaultkeyword-add', 'defaultkeyword-edit', 'languagelist-list', 'languagelist-add',  'languagelist-edit', 'languagelist-delete', 'languagewithkeyword-list', 'languagewithkeyword-edit', 'bulkimport-list'
                ],
            ],
            [
                'name' => 'subadmin',
                'sub_permission' => [ 
                   'subadmin-list', 'subadmin-add', 'subadmin-edit', 'subadmin-delete'
                ],
            ],
            [
                'name' => 'customersupport',
                'sub_permission' => [ 
                   'customersupport-show', 'customersupport-delete'
                ],
            ],
            [
                'name' => 'payment',
                'sub_permission' => [ 
                   'online-payment-list', 'cash-payment-list', 'wallet-payment-list'
                ],
            ],
            [
                'name' => 'company_type',
                'sub_permission' => [ 
                   'company_type-list', 'company_type-add', 'company_type-edit', 'company_type-delete'
                ],
            ],
            [
                'name' => 'corporate',
                'sub_permission' => [ 
                   'corporate-list', 'corporate-add', 'corporate-show', 'corporate-edit', 'corporate-delete'
                ],
            ],
            [
                'name' => 'managezone',
                'sub_permission' => [ 
                   'managezone-list', 'managezone-add', 'managezone-edit', 'managezone-delete'
                ],
            ],
            [
                'name' => 'airport',
                'sub_permission' => [ 
                   'airport-list', 'airport-add', 'airport-edit', 'airport-delete'
                ],
            ],
            [
                'name' => 'mail_template',
                'sub_permission' => [ 
                   'mail_template-list'
                ],
            ],
            [
                'name' => 'sms_template',
                'sub_permission' => [ 
                   'sms_template-list'
                ],
            ],
            [
                'name' => 'withdrawrequest',
                'sub_permission' => [ 
                   'withdrawrequest list','withdrawrequest add'
                ],
            ],
            [
                'name' => 'cancelled_reason',
                'sub_permission' => [ 
                   'cancelled_reason-list','cancelled_reason-add','cancelled_reason-edit','cancelled_reason-delete'
                ],
            ],
            [
                'name' => 'manage_corporate_document',
                'sub_permission' => [ 
                   'manage_corporate_document-list','manage_corporate_document-add','manage_corporate_document-edit','manage_corporate_document-delete'
                ],
            ],
            [
                'name' => 'faq',
                'sub_permission' => [ 
                   'faq-list','faq-add','faq-edit','faq-delete'
                ],
            ],
            [
                'name' => 'reference_program',
                'sub_permission' => [ 
                   'reference_program-list'
                ],
            ],
        ];

        SeederHelper::seedPermissions($permissions);

        $roles = [
            [
                'name' => 'admin',
                'status' => 1,
                'permissions' =>  [ 'role add', 'role list' ,'permission add', 'permission list','region list', 'region add', 'region edit', 'region delete','service list', 'service add', 'service show', 'service edit', 'service delete', 'special_rate list', 'special_rate add', 'special_rate edit', 'special_rate delete','driver list', 'driver add', 'driver show', 'driver edit', 'driver delete', 'pending driver', 'driver location',
                    'rider list', 'rider add', 'rider show', 'rider edit', 'rider delete','riderequest list', 'dispatch add', 'riderequest show', 'riderequest delete','document list', 'document add', 'document edit', 'document delete','driverdocument list', 'driverdocument add',  'driverdocument edit', 'driverdocument delete','coupon list', 'coupon add',  'coupon edit', 'coupon delete','additionalfees list', 'additionalfees add',  'additionalfees edit', 'additionalfees delete',
                    'sos list', 'sos add',  'sos edit', 'sos delete','complaint list', 'complaint add', 'complaint show',  'complaint edit', 'complaint delete','pushnotification list', 'pushnotification add',  'pushnotification delete','terms condition', 'privacy policy', 'pages list', 'pages add', 'pages show',  'pages edit', 'pages delete','report list', 'driverearning list', 'adminrearning list', 'service-wise-report', 'corporate-report list','screen-list', 'defaultkeyword-list', 'defaultkeyword-add', 'defaultkeyword-edit', 'languagelist-list', 'languagelist-add',  'languagelist-edit', 'languagelist-delete', 'languagewithkeyword-list', 'languagewithkeyword-edit', 'bulkimport-list','subadmin-list', 'subadmin-add', 'subadmin-edit', 'subadmin-delete',
                    'customersupport-show', 'customersupport-delete','online-payment-list', 'cash-payment-list', 'wallet-payment-list','company_type-list', 'company_type-add', 'company_type-edit', 'company_type-delete','corporate-list', 'corporate-add', 'corporate-show', 'corporate-edit', 'corporate-delete','managezone-list', 'managezone-add', 'managezone-edit', 'managezone-delete','airport-list', 'airport-add', 'airport-edit', 'airport-delete','mail_template-list','sms_template-list','withdrawrequest list','cancelled_reason-list','cancelled_reason-add','cancelled_reason-edit','cancelled_reason-delete',
                    'manage_corporate_document-list','manage_corporate_document-add','manage_corporate_document-edit','manage_corporate_document-delete','faq-list','faq-add','faq-edit','faq-delete', 'reference_program-list',
               ],
            ],
            [
                'name' => 'rider',
                'status' => 1,
                'permissions' => []
            ],
            [
                'name' => 'driver',
                'status' => 1,
                'permissions' => []
            ],
            [
                'name' => 'corporate',
                'status' => 1,
                'permissions' => [
                'withdrawrequest list','withdrawrequest add'
                ]
            ],
        ];

        SeederHelper::seedRoles($roles);

        $users = [
            [
                'id' => 1,
                'first_name' => 'Admin',
                'last_name' => 'Admin',
                'username' => 'admin',
                'contact_number' => '+919876543210',
                'address' => NULL,
                'email' => 'admin@admin.com',
                'password' => bcrypt('12345678'),
                'email_verified_at' => NULL,
                'user_type' => 'admin',
                'player_id' => NULL,
                'remember_token' => NULL,
                'last_notification_seen' => NULL,
                'status' => 'active',
                'timezone' => 'UTC',
                'display_name' => 'Admin',
                'created_at' => Carbon::now()->format('Y-m-d H:i:s'),
                'updated_at' => NULL,
            ],
        ];

        foreach ($users as $value) {
            $user = User::create($value);
            $user->assignRole($value['user_type']);
        }

    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        //
    }
};
