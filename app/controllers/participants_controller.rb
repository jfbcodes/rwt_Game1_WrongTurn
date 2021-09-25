class ParticipantsController < ApplicationController
  def account
    participant = Participant.find_by_uuid(params[:uuid])
    render json: {
      status: 'ok',
      participant: participant.serialize_account
    }
  end

  # Commands
  # =====================
  def create
    participant = Participant.new
    participant.username = params['userName']
    participant.email = params['email']
    participant.phone = params['phoneNumber']
    participant.referral_id = params['referral_id']

    if participant.save
      render json: {
        status: 'ok',
        participant: participant.serialize_full
      }
    else
      render json: {
        status: 'error',
        details: participant.errors.messages,
        message: 'Hmm... there was an error creating participant'
      }
    end
  end

  def update_account
    participant = Participant.find_by_id(params[:participant_id])
    previous_username = participant.username
    previous_email = participant.email
    if participant.update({
                       user_name: params[:userName],
                       email: params[:email],
                       phone_country_code: params[:phoneCountryCode],
                       phone_number: params[:phoneNumber]
                     })


      if previous_email != participant.email

        Analytics.track({ user_id: participant.id,
                          event: 'Changes email',
                          properties: { next_email: participant.email }
                        })

      end

      render json: {
        status: 'ok',
        participant: participant.serialize_full
      }
    else
      render json: {
        status: 'error',
        message: 'error updating account'
      }
    end
  rescue StandardError
    render json: {
      status: 'error',
      message: 'error updating account'
    }
  end

  def signup_guest
    should_resend_phone_verification_code = Participant.find_by_uuid(params[:guestUUID]).present?
    participant = Participant.find_by_uuid(params[:guest_id]) || Participant.new

    participant.username = params[:userName]
    participant.email = params[:email]
    participant.phone = params[:phoneNumber]
    participant.referral_id = params[:referral_id]

    if participant.save
      render json: {
        status: 'ok',
        participant: participant.serialize_full
      }
    else
      render json: {
        status: 'error',
        details: participant.errors.details,
        message: 'error signing up guest'
      }
    end
  end

  def resend_phone_confirmation_code
    participant = Participant.find(params[:participant_id])
    if participant.present?
      participant.send_authy_code
      render json: {
        status: 'ok'
      }
    else
      render json: {
        status: 'error',
        message: 'Hmm could not find that participant'
      }
    end
  end

  def request_auth_code
    participant = Participant.find_by({  phone_number: params[:phone],
                                    phone_number_confirmed: true })
    if participant.present?
      participant.send_authy_code
      render json: {
        status: 'ok',
        participant_id: participant.id
      }
    else
      render json: {
        status: 'error',
        details: { phone_number: ['We don\'t recognize that phone number...'] },
        message: 'participant not found'
      }
    end
  end

  def verify_phone_number
    participant = Participant.find(params['participant_id'])
    if participant.present?
      response = Authy::API.verify({ id: participant.authy_id,
                                     token: params['code'] })
      if response.ok?
        if !participant.phone_number_confirmation
          participant.update({ phone_number_confirmation: true })
          Analytics.identify({
                               user_id: participant.uuid,
                               traits: {
                                 phone_number_confirmation: true
                               }
                             })
          Analytics.track({ user_id: participant.uuid, event: 'Signs up' })
        else
          Analytics.identify({ user_id: participant.uuid })
          Analytics.track({ user_id: participant.id,
                            event: 'Logs in' })
        end

        render json: {
          status: 'ok',
          participant: participant.serialize_full
        }
      else

        render json: {
          status: 'error',
          details: { auth_code: ['That code doesn\'t look right...'] },
          message: 'That code doesn\'t look right...'
        }
      end
    else
      render json: {
        status: 'error',
        details: { participant: ['not found'] },
        message: 'participant not found'
      }
    end
  end

  def create_with_membership
    participant = Participant.new

    room = Room.find_by(id: params[:automatically_add_to_room_id])

    participant.username = params['userName']
    participant.email = params['email']
    participant.password = params['password']

    participant.room_memberships.build({ room_id: room.id,
                                         role: 'member' })

    if participant.save!
      render json: {
        status: 'ok',
        participant: participant.serialize_full,
        jwt: Auth.issue_token({ participant_id: participant.id },
                              1.hours.to_i)
      }
    else
      render json: {
        status: 'error',
        message: 'hmm there was an error creating the participant'
      }
    end
  end

  def login
    participant = Participant.find_by_email(params['email'].downcase).try(:authenticate,
                                                                     params['password'])

    if participant
      render json: {
        status: 'ok',
        participant: participant.serialize_full,
        jwt: Auth.issue_token({ participant_id:
                                  participant.id }, 1.hours.to_i)
      }
    else
      render json: {
        status: 'error',
        message: 'the credentials were invalid'
      }
    end
  end
end
