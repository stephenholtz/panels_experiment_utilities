function [result, message] = send_alert_email(subject_line,message_line)
% This will send an email to the hard-coded email below with the
% subject line and message line. From the mathworks documentation.

    try
        my_address = 'experiment.holtz@gmail.com';
        setpref('Internet','E_mail',my_address);
        setpref('Internet','SMTP_Server','smtp.gmail.com');
        setpref('Internet','SMTP_Username',my_address);
        setpref('Internet','SMTP_Password','this_is_not_my_usual_password');
        props = java.lang.System.getProperties;
        props.setProperty('mail.smtp.auth','true');
        props.setProperty('mail.smtp.socketFactory.class', ...
                          'javax.net.ssl.SSLSocketFactory');
        props.setProperty('mail.smtp.socketFactory.port','465');
        
        sendmail(my_address, subject_line, message_line);
        
        result = 1;
        message = 'Email Sending OK';
        
    catch mailErr
        result = 0;
        message = ['Email Sending Failed: ' mailErr.message];
    end
end
