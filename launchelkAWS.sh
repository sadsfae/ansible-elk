#!/bin/sh
# Please set the above to variables
export AWS_ACCESS_KEY_ID=$MY_AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY=$MY_AWS_SECRET_ACCESS_KEY
aws ec2 request-spot-instances  --spot-price=0.05 --type persistent --instance-count 1 --launch-specification '
{
      "ImageId": "ami-2a0ff04a",
      "InstanceType": "m3.large",
      "KeyName": "elk2",
      "BlockDeviceMappings": [
        {
          "DeviceName": "/dev/sda1",
          "Ebs": {
            "DeleteOnTermination": true,
            "VolumeType": "gp2",
            "VolumeSize": 12,
            "SnapshotId": "snap-3f387f6e"
          }
        },
        {
          "DeviceName": "/dev/xvdca",
          "VirtualName": "ephemeral0"
        }
      ],
      "NetworkInterfaces": [
        {
          "DeviceIndex": 0,
          "DeleteOnTermination": true,
          "AssociatePublicIpAddress": true,
          "Groups": [
          ]
        }
      ]

}'
