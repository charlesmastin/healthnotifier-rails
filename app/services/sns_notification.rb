class SNSNotification

    # each method returns an int for the number of devices notified
    # allowing the calling code to better handle email failover or delay sending for additional communications
    # as to not overwhelm client apps with a notification blast

    # transactional notifications we support
    # request access - to granter
    # granted / accepted access - to auditor
    # status change provider
    # postscan
    # emergency 

    # marketing (all notifications - use topics on the SNS)

    def self.get_client
        # TODO: cache client instance bro
        sns = Aws::SNS::Client.new(
            region: Rails.application.config.aws_s3[:region],
            access_key_id: Rails.application.config.aws_s3[:access_key_id],
            secret_access_key: Rails.application.config.aws_s3[:secret_access_key]
        )
        return sns
    end

    def self.test(patient, ios_notification = nil, android_notification = nil)
        # do we have a device and an endpoint brizzle
        notified = 0
        devices = AccountDevice.where(:account_id => patient.account.account_id)
        if devices.count > 0
            devices.each do |device|
                if device.endpoint_arn.present?
                    sns_message = nil
                    lsq_payload = {
                        event: "test", # client should then reload account to check provider status itself
                        patient_uuid: patient.uuid
                    }
                    if device.platform == "ios"
                        if ios_notification.present?
                            notification = ios_notification
                        else
                            notification = {
                                aps: {
                                    alert: "Hello #{patient.first_name}, this a test notification",
                                    sound: "default",
                                    badge: 99
                                },
                                data: lsq_payload
                            }
                        end
                        sns_message = {
                            APNS_SANDBOX: notification.to_json,
                            APNS: notification.to_json   
                        }
                        
                    end
                    if device.platform == "android"
                        if android_notification.present?
                            notification = android_notification
                        else
                            notification = {
                                notification: {
                                    text: "Hello #{patient.first_name}, this a test notification",
                                    sound: "default"
                                },
                                data: lsq_payload
                            }
                        end
                        sns_message = {
                            GCM: notification.to_json,
                        }
                    end
                    if sns_message != nil
                        if self.publish(device, sns_message)
                            notified += 1
                        end
                    end
                end
            end
        else
        end
        notified
    end

    def self.notify_devices(devices, body)
        notified = 0
        devices.each do |device|
            if self.notify_device(device, body)
                notified += 1
            end
        end
        notified
    end

    def self.notify_device(device, body)
        # for one-off messages JUST TO the specified device, no relation to any other devices for dat account
        if device.endpoint_arn.present?
            sns_message = nil
            if device.platform == "ios"
                notification = {
                    aps: {
                        alert: body,
                        sound: "default"
                    }
                }
                sns_message = {
                    APNS_SANDBOX: notification.to_json,
                    APNS: notification.to_json   
                }
            end
            if device.platform == "android"
                notification = {
                    notification: {
                        text: body,
                        sound: "default"
                    }
                }
                sns_message = {
                    GCM: notification.to_json,
                }
            end
            if sns_message != nil
                return self.publish(device, sns_message)
            end
        end
        return false # if successful
    end

    def self.publish(device, sns_message)
        begin
            sns = self.get_client
            message = sns.publish(target_arn: device.endpoint_arn, message: sns_message.to_json, message_structure: "json")            
            device.notification_count += 1
            device.save
            return true
        rescue Aws::SNS::Errors::EndpointDisabled
            return false
        rescue Aws::SNS::Errors::InvalidParameter
            # aka TargetARN doesn't exist, like it was deleted on SNS
            return false
        rescue
            # something else though
            return false
        end
    end

    def self.publish_topic(topic_arn, body)
        # ALL THE PEOPLES IN DA WORLDS
        # arn:aws:sns:us-west-2:631082279464:platform-notification

        # TOPIC for providers

        # TOPIC for platforms (ios, android)

        # TOPIC per organization


        # {
        #     "default": "Hello Sauce", 
        #     "APNS_SANDBOX":"{\"aps\":{\"alert\":\"Hello Sauce\"}}", 
        #     "GCM": "{ \"notification\": { \"text\": \"Hello Sauce\" } }", 
        # }
    end

    def self.network_request_access(auditor, granter)
        # clicking takes users to the notifications inbox if their platform supports it
        # at the very least, to the profile for the granter
        # DO NOT go into the nested patient network screens under profile as those are subject to deletion
        # generally speaking, send a payload and expect the client to handle the interaction
        # for something standard like this we could also pass most content as variables
        # and use the localized strings and templates to re-present the information locally, potentially
        # at least this is how we do it in foreground mode 
        devices = AccountDevice.where(:account_id => granter.account.account_id)
        notified = 0
        if devices.count > 0
            devices.each do |device|
                if device.endpoint_arn.present?
                    sns_message = nil
                    lsq_payload = {
                        event: "patient-network-request",
                        granter_uuid: "#{granter.uuid}",
                        auditor_uuid: "#{auditor.uuid}" 
                    }
                    if device.platform == "ios"
                        notification = {
                            aps: {
                                alert: {
                                    title: "Request to join LifeCircle",
                                    body: "#{auditor.fullname} would like to join #{granter.first_name}’s LifeCircle" 
                                },
                                sound: "default", badge: 1 # calculate the actual total here based on outstanding stuffs
                            },
                            data: lsq_payload
                        }
                        sns_message = {
                            APNS_SANDBOX: notification.to_json,
                            APNS: notification.to_json   
                        }
                    end
                    if device.platform == "android"
                        notification = {
                            notification: {
                                text: "#{auditor.fullname} would like to join #{granter.first_name}’s LifeCircle",
                                sound: "default"
                            },
                            data: lsq_payload
                        }
                        sns_message = {
                            GCM: notification.to_json,
                        }
                    end
                    if sns_message != nil
                        # learn my ruby code golf
                        if self.publish(device, sns_message)
                            notified += 1
                        end
                    end
                end
            end
        else

        end
        notified
    end
    
    def self.network_access_granted(auditor, granter)
        # level of access is not relevant
        # expect clicking CTA to be handled as a Lifesquare network view in the apps
        devices = AccountDevice.where(:account_id => auditor.account.account_id)
        notified = 0
        if devices.count > 0
            devices.each do |device|
                if device.endpoint_arn.present?
                    sns_message = nil
                    lsq_payload = {
                        event: "patient-network-granted",
                        granter_uuid: "#{granter.uuid}",
                        auditor_uuid: "#{auditor.uuid}" 
                    }
                    if device.platform == "ios"
                        # title: "Request to join LifeCircle",
                        notification = {
                            aps: {
                                alert: {
                                    body: "#{granter.fullname} added you to their LifeCircle"
                                },
                                sound: "default" # calculate the actual total here based on outstanding stuffs
                            },
                            data: lsq_payload
                        }
                        sns_message = {
                            APNS_SANDBOX: notification.to_json,
                            APNS: notification.to_json   
                        }
                    end
                    if device.platform == "android"
                        notification = {
                            notification: {
                                text: "#{granter.fullname} added you to their LifeCircle",
                                sound: "default"
                            },
                            data: lsq_payload
                        }
                        sns_message = {
                            GCM: notification.to_json,
                        }
                    end
                    if sns_message != nil
                        # learn my ruby code golf
                        if self.publish(device, sns_message)
                            notified += 1
                        end
                    end
                end
            end
        else

        end
        notified
    end

    def self.network_request_declined(auditor, granter)
        # silent push
        return 0
    end

    def self.network_access_revoked(auditor, granter)
        # silent push for real though
        devices = AccountDevice.where(:account_id => auditor.account.account_id)
        notified = 0
        if devices.count > 0
            devices.each do |device|
                if device.endpoint_arn.present?
                    sns_message = nil
                    lsq_payload = {
                        event: "patient-network-revoked",
                        granter_uuid: "#{granter.uuid}",
                        auditor_uuid: "#{auditor.uuid}" 
                    }
                    if device.platform == "ios"
                        notification = {
                            aps: {
                                alert: {
                                    body: "#{granter.fullname} removed you from their LifeCircle"
                                },
                            },
                            data: lsq_payload
                        }
                        sns_message = {
                            APNS_SANDBOX: notification.to_json,
                            APNS: notification.to_json   
                        }
                    end
                    if device.platform == "android"
                        notification = {
                            notification: {
                                text: "#{granter.fullname} removed you from their LifeCircle"
                            },
                            data: lsq_payload
                        }
                        sns_message = {
                            GCM: notification.to_json,
                        }
                    end
                    if sns_message != nil
                        # learn my ruby code golf
                        if self.publish(device, sns_message)
                            notified += 1
                        end
                    end
                end
            end
        else

        end
        notified
    end

    def self.provider_status_change(credentials)
        # level of access is not relevant
        # expect clicking CTA to be handled as a Lifesquare network view in the apps
        # we don't do pending / in-progress from the admin side, it's just waiting, there is no tease just the final word
        # if approved
        
        # if denied
        body = nil
        if credentials.accepted?
            body = "Provider Access Approved!"
        elsif credentials.rejected?
            body = "Provider Access Denied!"
        else
            return 0 # the wrong kind of return though
        end

        devices = AccountDevice.where(:account_id => credentials.patient.account.account_id)
        notified = 0
        if devices.count > 0
            devices.each do |device|
                if device.endpoint_arn.present?
                    sns_message = nil
                    lsq_payload = {
                        event: "provider-status", # client should then reload account to check provider status itself
                        value: credentials.status
                    }
                    if device.platform == "ios"
                        # title: "Request to join LifeCircle",
                        notification = {
                            aps: {
                                alert: {
                                    body: body
                                },
                                sound: "default" # calculate the actual total here based on outstanding stuffs
                            },
                            data: lsq_payload
                        }
                        sns_message = {
                            APNS_SANDBOX: notification.to_json,
                            APNS: notification.to_json   
                        }
                    end
                    if device.platform == "android"
                        notification = {
                            notification: {
                                text: body,
                                sound: "default"
                            },
                            data: lsq_payload
                        }
                        sns_message = {
                            GCM: notification.to_json,
                        }
                    end
                    if sns_message != nil
                        # learn my ruby code golf
                        if self.publish(device, sns_message)
                            notified += 1
                        end
                    end
                end
            end
        else

        end
        notified
    end

    def self.postscansms(auditor, body, scanned_patient, phone, scanner_name)
        self.postscan_default(auditor, body, scanned_patient, false, phone, scanner_name)
    end

    def self.postscan(auditor, body, scanned_patient, phone, latitude, longitude, geo)
        self.postscan_default(auditor, body, scanned_patient, true, phone, nil, latitude, longitude, geo)
    end

    def self.postscan_default(auditor, body, scanned_patient, native, phone, scanner_name, latitude=nil, longitude=nil, geo=nil)
        # internally we could use a generic delivery logic
        # level of access is not relevant
        # expect clicking CTA to be handled as a Lifesquare network view in the apps
        # we don't do pending / in-progress from the admin side, it's just waiting, there is no tease just the final word
        # if approved
        

        devices = AccountDevice.where(:account_id => auditor.account.account_id)
        notified = 0
        if devices.count > 0
            devices.each do |device|
                if device.endpoint_arn.present?
                    sns_message = nil
                    lsq_payload = {
                        phone: phone, # TODO: ensure we are mad pre-scrubbed on this end
                        event: "postscan", # client should then reload account to check provider status itself
                        patient_uuid: scanned_patient.uuid,
                        lifesquare: scanned_patient.lifesquare.lifesquare_uid # OH android still needs dis… w/e
                    }
                    if latitude && longitude
                        lsq_payload['latitude'] = latitude
                        lsq_payload['longitude'] = longitude
                    end
                    if geo
                        lsq_payload['geo'] = geo.formatted_address
                    end
                    # TODO: pass scanner details, like name, photo url, provider status, bro
                    if device.platform == "ios"
                        # title: "Request to join LifeCircle",
                        category = "POSTSCANSMS"
                        if native
                            category = "POSTSCAN"
                        end
                        notification = {
                            aps: {
                                category: category,
                                alert: {
                                    body: body
                                },
                                sound: "default" # calculate the actual total here based on outstanding stuffs
                            },
                            data: lsq_payload
                        }
                        sns_message = {
                            APNS_SANDBOX: notification.to_json,
                            APNS: notification.to_json   
                        }
                    end
                    if device.platform == "android"
                        notification = {
                            notification: {
                                text: body,
                                sound: "default"
                            },
                            data: lsq_payload
                        }
                        sns_message = {
                            GCM: notification.to_json,
                        }
                    end
                    if sns_message != nil
                        # learn my ruby code golf
                        if self.publish(device, sns_message)
                            notified += 1
                        end
                    end
                end
            end
        else

        end
        notified
    end

end