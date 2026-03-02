{!! html()->form('POST' , route('envSetting'))->attribute('data-toggle', 'validator')->open() !!}

    {!! html()->hidden('id', null)->class('form-control') !!}
    {!! html()->hidden('page', $page)->class('form-control') !!}
    {!! html()->hidden('type', 'mail')->class('form-control') !!}

    
    <div class="col-md-12 mt-20">
        <div class="row">
            @foreach(config('constant.MAIL_SETTING') as $key => $value)
                <div class="col-md-6">
                    <div class="form-group">
                        <label class="form-control-label text-capitalize">{{ strtolower(str_replace('_',' ',$key)) }}</label>
                        @if( !env('APP_DEMO') && auth()->user()->hasRole('admin'))
                            <input type="{{$key=='MAIL_PASSWORD'?'password':'text'}}" value="{{ $value }}" name="ENV[{{$key}}]" class="form-control" placeholder="{{ config('constant.MAIL_PLACEHOLDER.'.$key) }}">
                        @else
                            <input type="{{$key=='MAIL_PASSWORD'?'password':'text'}}" value="" name="ENV[{{$key}}]" class="form-control" placeholder="{{ config('constant.MAIL_PLACEHOLDER.'.$key) }}">
                        @endif
                    </div>
                </div>
            @endforeach
        </div>
    </div>
    {!! html()->submit(__('message.save'))->class('btn btn-md btn-primary float-md-right') !!}
    {!! html()->form()->close() !!}